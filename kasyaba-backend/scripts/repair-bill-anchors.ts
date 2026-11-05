import { Prisma, PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const DEFAULT_OLDER_THAN_DAYS = 60;
const DAY_MS = 24 * 60 * 60 * 1000;

interface CliOptions {
  apply: boolean;
  deletePastUnpaid: boolean;
  olderThanDays: number;
  olderThanDaysProvided: boolean;
  help: boolean;
}

interface AnchorPlan {
  id: string;
  name: string;
  recurrence: string;
  startsOn: Date;
  currentDayOfMonth: number | null;
  currentDayOfWeek: number | null;
  nextDayOfMonth: number | null;
  nextDayOfWeek: number | null;
  changed: boolean;
}

function printUsage() {
  console.log(`Usage:
  npm run db:repair-bills -- [--apply] [--delete-past-unpaid [--older-than-days=N]]

Options:
  --apply                  Write anchor repairs. Without it the script is a dry run.
  --delete-past-unpaid     Delete stale upcoming/overdue instances belonging to
                           recurring (monthly/weekly) templates. Requires --apply.
                           Paid and cancelled instances are never deleted.
  --older-than-days=N      Age threshold for deletion (default ${DEFAULT_OLDER_THAN_DAYS}).
  --help                   Show this help.

Deletion requires BOTH --apply and --delete-past-unpaid.
`);
}

function parseOlderThanDays(raw: string): number {
  const value = Number(raw);
  if (!Number.isInteger(value) || value < 0) {
    throw new Error('--older-than-days must be a non-negative integer');
  }
  return value;
}

function parseArgs(argv: string[]): CliOptions {
  let apply = false;
  let deletePastUnpaid = false;
  let olderThanDays = DEFAULT_OLDER_THAN_DAYS;
  let olderThanDaysProvided = false;
  let help = false;

  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--apply') {
      apply = true;
    } else if (arg === '--delete-past-unpaid') {
      deletePastUnpaid = true;
    } else if (arg === '--help' || arg === '-h') {
      help = true;
    } else if (arg.startsWith('--older-than-days=')) {
      olderThanDays = parseOlderThanDays(
        arg.slice('--older-than-days='.length),
      );
      olderThanDaysProvided = true;
    } else if (arg === '--older-than-days') {
      const raw = argv[++i];
      if (raw === undefined) {
        throw new Error('--older-than-days requires a value');
      }
      olderThanDays = parseOlderThanDays(raw);
      olderThanDaysProvided = true;
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  return {
    apply,
    deletePastUnpaid,
    olderThanDays,
    olderThanDaysProvided,
    help,
  };
}

function deriveAnchors(template: {
  recurrence: string;
  startsOn: Date;
  dayOfMonth: number | null;
  dayOfWeek: number | null;
}): { dayOfMonth: number | null; dayOfWeek: number | null } {
  let dayOfMonth = template.dayOfMonth;
  let dayOfWeek = template.dayOfWeek;

  if (template.recurrence === 'monthly' && dayOfMonth === null) {
    dayOfMonth = template.startsOn.getUTCDate();
  } else if (template.recurrence === 'weekly' && dayOfWeek === null) {
    dayOfWeek = template.startsOn.getUTCDay();
  }

  return { dayOfMonth, dayOfWeek };
}

function formatAnchor(value: number | null): string {
  return value === null ? 'null' : String(value);
}

function formatDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

async function repairAnchors(options: CliOptions) {
  const templates = await prisma.billTemplate.findMany({
    orderBy: { createdAt: 'asc' },
  });

  const plans: AnchorPlan[] = templates.map((template) => {
    const next = deriveAnchors(template);
    return {
      id: template.id,
      name: template.name,
      recurrence: template.recurrence,
      startsOn: template.startsOn,
      currentDayOfMonth: template.dayOfMonth,
      currentDayOfWeek: template.dayOfWeek,
      nextDayOfMonth: next.dayOfMonth,
      nextDayOfWeek: next.dayOfWeek,
      changed:
        next.dayOfMonth !== template.dayOfMonth ||
        next.dayOfWeek !== template.dayOfWeek,
    };
  });

  console.log(`\nBill templates: ${plans.length}`);
  let changeCount = 0;
  for (const plan of plans) {
    if (!plan.changed) {
      console.log(
        `  = ${plan.name} [${plan.recurrence}] (${plan.id}) — no change ` +
          `(dayOfMonth=${formatAnchor(plan.currentDayOfMonth)}, dayOfWeek=${formatAnchor(plan.currentDayOfWeek)})`,
      );
      continue;
    }

    changeCount++;
    const changes: string[] = [];
    if (plan.nextDayOfMonth !== plan.currentDayOfMonth) {
      changes.push(
        `dayOfMonth ${formatAnchor(plan.currentDayOfMonth)} -> ${formatAnchor(plan.nextDayOfMonth)}`,
      );
    }
    if (plan.nextDayOfWeek !== plan.currentDayOfWeek) {
      changes.push(
        `dayOfWeek ${formatAnchor(plan.currentDayOfWeek)} -> ${formatAnchor(plan.nextDayOfWeek)}`,
      );
    }
    console.log(
      `  ~ ${plan.name} [${plan.recurrence}] (${plan.id}) startsOn=${formatDate(plan.startsOn)}: ${changes.join(', ')}`,
    );
  }

  if (changeCount === 0) {
    console.log('\nNo anchor repairs needed.');
    return;
  }

  if (!options.apply) {
    console.log(
      `\nDRY RUN: ${changeCount} template(s) would be updated. Re-run with --apply to write.`,
    );
    return;
  }

  for (const plan of plans) {
    if (!plan.changed) continue;
    await prisma.billTemplate.update({
      where: { id: plan.id },
      data: {
        dayOfMonth: plan.nextDayOfMonth,
        dayOfWeek: plan.nextDayOfWeek,
      },
    });
  }
  console.log(`\nApplied anchor repairs to ${changeCount} template(s).`);
}

async function deleteStaleInstances(options: CliOptions) {
  const cutoff = new Date(Date.now() - options.olderThanDays * DAY_MS);
  const where: Prisma.BillInstanceWhereInput = {
    status: { in: ['upcoming', 'overdue'] },
    dueDate: { lt: cutoff },
    template: { is: { recurrence: { in: ['monthly', 'weekly'] } } },
  };

  const stale = await prisma.billInstance.findMany({
    where,
    select: { id: true, name: true, dueDate: true, status: true },
    orderBy: { dueDate: 'asc' },
  });

  const counts = { upcoming: 0, overdue: 0 };
  for (const bill of stale) {
    if (bill.status === 'upcoming') counts.upcoming++;
    if (bill.status === 'overdue') counts.overdue++;
  }

  console.log(
    `\nStale unpaid recurring-bill instances before ${cutoff.toISOString()} ` +
      `(older than ${options.olderThanDays} day(s)): ${stale.length} ` +
      `(upcoming=${counts.upcoming}, overdue=${counts.overdue})`,
  );
  for (const bill of stale) {
    console.log(
      `  - ${bill.name} (${bill.id}) due ${formatDate(bill.dueDate)} [${bill.status}]`,
    );
  }

  if (stale.length === 0) return;

  if (!options.apply) {
    console.warn(
      `WARNING: dry run — ${stale.length} instance(s) would be DELETED. ` +
        'Deletion requires BOTH --apply and --delete-past-unpaid.',
    );
    return;
  }

  console.warn(
    `WARNING: deleting ${stale.length} unpaid instance(s). This cannot be undone. ` +
      'Paid and cancelled instances are excluded.',
  );

  // Re-evaluate the predicate at delete time so instances paid/cancelled
  // between the read above and this write are preserved.
  const deleted = await prisma.billInstance.deleteMany({ where });
  console.log(`Deleted ${deleted.count} bill instance(s).`);
}

async function main() {
  const options = parseArgs(process.argv.slice(2));
  if (options.help) {
    printUsage();
    return;
  }

  console.log(
    `Kasyaba bill anchor repair — ${options.apply ? 'APPLY' : 'DRY RUN'}`,
  );

  if (options.olderThanDaysProvided && !options.deletePastUnpaid) {
    console.warn(
      'WARNING: --older-than-days was supplied without --delete-past-unpaid; it will be ignored.',
    );
  }

  await repairAnchors(options);

  if (options.deletePastUnpaid) {
    await deleteStaleInstances(options);
  }

  console.log(
    '\nNote: this script does not generate bill instances. The worker bill_generation job will create upcoming instances.',
  );
}

main()
  .catch((err) => {
    console.error('Bill anchor repair failed:', err);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
