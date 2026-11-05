import type { BillTemplate } from '@prisma/client';
import { prisma } from '../../config/database';
import { ConflictError, NotFoundError } from '../../lib/errors';
import { endOfZonedDay, startOfZonedDay, zonedDateAnchorUtc } from '../../lib/zoned-dates';
import type { CreateBillTemplateInput, UpdateBillTemplateInput } from './validation';

const DAY_MS = 24 * 60 * 60 * 1000;

interface UtcTimeOfDay {
  hours: number;
  minutes: number;
  seconds: number;
  milliseconds: number;
}

function utcTimeOfDay(date: Date): UtcTimeOfDay {
  return {
    hours: date.getUTCHours(),
    minutes: date.getUTCMinutes(),
    seconds: date.getUTCSeconds(),
    milliseconds: date.getUTCMilliseconds(),
  };
}

function daysInUtcMonth(year: number, monthIndex: number): number {
  // `monthIndex + 1, day 0` normalizes month overflow to the last day of the
  // requested month.
  return new Date(Date.UTC(year, monthIndex + 1, 0)).getUTCDate();
}

function utcOccurrence(
  year: number,
  monthIndex: number,
  day: number,
  time: UtcTimeOfDay,
): Date {
  // Never carry the day across months: a bill anchored on the 31st falls back
  // to the last valid day for shorter months and returns to the 31st later.
  return new Date(
    Date.UTC(
      year,
      monthIndex,
      Math.min(day, daysInUtcMonth(year, monthIndex)),
      time.hours,
      time.minutes,
      time.seconds,
      time.milliseconds,
    ),
  );
}

function addUtcMonthsClamped(date: Date, months: number): Date {
  return utcOccurrence(
    date.getUTCFullYear(),
    date.getUTCMonth() + months,
    date.getUTCDate(),
    utcTimeOfDay(date),
  );
}

async function upsertBillInstance(
  userId: string,
  template: BillTemplate,
  dueDate: Date,
  created: number[],
) {
  const existing = await prisma.billInstance.findUnique({
    where: {
      templateId_dueDate: {
        templateId: template.id,
        dueDate,
      },
    },
    select: { id: true },
  });

  await prisma.billInstance.upsert({
    where: {
      templateId_dueDate: {
        templateId: template.id,
        dueDate,
      },
    },
    create: {
      userId,
      templateId: template.id,
      name: template.name,
      amount: template.defaultAmount,
      dueDate,
    },
    update: {},
  });

  if (!existing) created.push(1);
}

export async function listBillTemplates(userId: string) {
  return prisma.billTemplate.findMany({
    where: { userId, isActive: true },
    orderBy: { createdAt: 'desc' },
  });
}

async function findAccessibleCategory(userId: string, categoryId?: string | null) {
  if (categoryId) {
    const category = await prisma.expenseCategory.findFirst({
      where: { id: categoryId, isArchived: false, OR: [{ userId }, { userId: null }] },
      select: { id: true },
    });
    if (!category) throw new NotFoundError('Category not found');
    return category.id;
  }

  const fallback = await prisma.expenseCategory.findFirst({
    where: { userId: null, name: 'Other', isArchived: false },
    select: { id: true },
  });
  if (!fallback) throw new NotFoundError('Default expense category not found');
  return fallback.id;
}

export async function createBillTemplate(userId: string, input: CreateBillTemplateInput) {
  if (input.categoryId) await findAccessibleCategory(userId, input.categoryId);

  const startsOn = new Date(input.startsOn);

  // Older clients omit the recurrence anchor fields. Derive them from the
  // start date server-side so instance generation always has a bounded anchor
  // instead of falling back to an unbounded loop.
  const dayOfMonth = input.recurrence === 'monthly' && input.dayOfMonth == null
    ? startsOn.getUTCDate()
    : input.dayOfMonth ?? null;
  const dayOfWeek = input.recurrence === 'weekly' && input.dayOfWeek == null
    ? startsOn.getUTCDay()
    : input.dayOfWeek ?? null;

  const template = await prisma.billTemplate.create({
    data: {
      userId,
      name: input.name,
      defaultAmount: input.defaultAmount,
      categoryId: input.categoryId || null,
      recurrence: input.recurrence,
      dayOfWeek,
      dayOfMonth,
      startsOn,
      endsOn: input.endsOn ? new Date(input.endsOn) : null,
      reminderLeadDays: input.reminderLeadDays,
      isActive: input.isActive,
    },
  });
  await generateBillInstances(userId);
  return template;
}

export async function updateBillTemplate(userId: string, id: string, input: UpdateBillTemplateInput) {
  const existing = await prisma.billTemplate.findFirst({ where: { id, userId } });
  if (!existing) throw new NotFoundError('Bill template not found');
  if (input.categoryId !== undefined) {
    await findAccessibleCategory(userId, input.categoryId);
  }

  const data: any = { ...input };
  if (input.startsOn) data.startsOn = new Date(input.startsOn);
  if (input.endsOn !== undefined) data.endsOn = input.endsOn ? new Date(input.endsOn) : null;
  if (input.dayOfWeek !== undefined) data.dayOfWeek = input.dayOfWeek ?? null;
  if (input.dayOfMonth !== undefined) data.dayOfMonth = input.dayOfMonth ?? null;

  const template = await prisma.billTemplate.update({ where: { id }, data });

  // A due-day or amount change must rebuild the schedule. Delete only unpaid,
  // non-cancelled instances from today onward so paid/cancelled history stays
  // intact, then regenerate from the updated template.
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';
  const todayStart = startOfZonedDay(new Date(), timeZone);

  await prisma.billInstance.deleteMany({
    where: {
      userId,
      templateId: id,
      status: { notIn: ['paid', 'cancelled'] },
      dueDate: { gte: todayStart },
    },
  });
  await generateBillInstances(userId);

  return template;
}

export async function archiveBillTemplate(userId: string, id: string) {
  const existing = await prisma.billTemplate.findFirst({ where: { id, userId } });
  if (!existing) throw new NotFoundError('Bill template not found');
  return prisma.billTemplate.update({
    where: { id },
    data: { isActive: false },
  });
}

export async function listBills(userId: string, query: Record<string, any>) {
  const page = Number(query.page) || 1;
  const limit = Math.min(Number(query.limit) || 200, 500);
  const where: any = { userId };

  if (query.status) where.status = query.status;
  if (query.from || query.to) {
    where.dueDate = {};
    if (query.from) where.dueDate.gte = new Date(query.from);
    if (query.to) where.dueDate.lte = new Date(query.to + 'T23:59:59.999Z');
  }

  // Bounded response: paid/overdue instances accumulate over the years. Newest
  // first keeps upcoming instances inside the page window instead of filling
  // it with old history.
  const [total, rows] = await Promise.all([
    prisma.billInstance.count({ where }),
    prisma.billInstance.findMany({
      where,
      orderBy: { dueDate: 'desc' },
      skip: (page - 1) * limit,
      take: limit,
      include: {
        template: {
          select: {
            recurrence: true,
            categoryId: true,
            reminderLeadDays: true,
          },
        },
      },
    }),
  ]);

  return { rows, page, limit, total };
}

export async function markBillPaid(userId: string, billId: string, accountId: string) {
  return prisma.$transaction(async (tx) => {
    const account = await tx.financialAccount.findFirst({
      where: { id: accountId, userId, isArchived: false },
      select: { id: true },
    });
    if (!account) throw new NotFoundError('Account not found');

    const bill = await tx.billInstance.findFirst({ where: { id: billId, userId } });
    if (!bill) throw new NotFoundError('Bill not found');
    if (bill.status === 'paid') throw new ConflictError('Bill is already paid');
    if (bill.status === 'cancelled') throw new ConflictError('Cancelled bills cannot be paid');

    // The conditional update makes concurrent payment requests mutually
    // exclusive. A second request waits for the first transaction and then
    // observes that the bill is already paid.
    const claimed = await tx.billInstance.updateMany({
      where: { id: billId, userId, status: { notIn: ['paid', 'cancelled'] } },
      data: { status: 'paid', paidAt: new Date() },
    });
    if (claimed.count !== 1) throw new ConflictError('Bill is already paid');

    let categoryId: string | null = null;
    if (bill.templateId) {
      const template = await tx.billTemplate.findFirst({
        where: { id: bill.templateId, userId },
        select: { categoryId: true },
      });
      categoryId = template?.categoryId ?? null;
    }

    if (categoryId) {
      const category = await tx.expenseCategory.findFirst({
        where: { id: categoryId, isArchived: false, OR: [{ userId }, { userId: null }] },
        select: { id: true },
      });
      categoryId = category?.id ?? null;
    }
    categoryId ??= (await tx.expenseCategory.findFirst({
      where: { userId: null, name: 'Other', isArchived: false },
      select: { id: true },
    }))?.id ?? null;
    if (!categoryId) throw new NotFoundError('Default expense category not found');

    const expense = await tx.expenseEntry.create({
      data: {
        userId,
        accountId: account.id,
        categoryId,
        amount: bill.amount,
        description: `${bill.name} (paid bill)`,
        spentAt: new Date(),
      },
    });

    return tx.billInstance.update({
      where: { id: billId },
      data: { expenseEntryId: expense.id },
    });
  });
}

export async function markBillUnpaid(userId: string, billId: string) {
  return prisma.$transaction(async (tx) => {
    const bill = await tx.billInstance.findFirst({ where: { id: billId, userId } });
    if (!bill) throw new NotFoundError('Bill not found');
    if (bill.status !== 'paid') {
      throw new ConflictError('Only paid bills can be marked unpaid');
    }

    // Conditional claim keeps concurrent unpaid requests mutually exclusive.
    const claimed = await tx.billInstance.updateMany({
      where: { id: billId, userId, status: 'paid' },
      data: { status: 'upcoming', paidAt: null, expenseEntryId: null },
    });
    if (claimed.count !== 1) {
      throw new ConflictError('Bill state changed. Refresh and try again.');
    }

    if (bill.expenseEntryId) {
      await tx.expenseEntry.deleteMany({
        where: { id: bill.expenseEntryId, userId },
      });
    }

    return tx.billInstance.findUnique({ where: { id: billId } });
  });
}

export async function cancelBill(userId: string, billId: string) {
  // A bill that has already been paid must be marked unpaid first: otherwise
  // the linked expense would remain counted while the bill shows cancelled.
  const claimed = await prisma.billInstance.updateMany({
    where: { id: billId, userId, status: { notIn: ['paid', 'cancelled'] } },
    data: { status: 'cancelled' },
  });
  if (claimed.count === 0) {
    const bill = await prisma.billInstance.findFirst({
      where: { id: billId, userId },
    });
    if (!bill) throw new NotFoundError('Bill not found');
    if (bill.status === 'paid') {
      throw new ConflictError('Paid bills cannot be cancelled. Mark the bill unpaid first.');
    }
    throw new ConflictError('Bill is already cancelled');
  }
  return prisma.billInstance.findUnique({ where: { id: billId } });
}

export async function generateBillInstances(userId: string, monthsAhead = 2) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';

  const templates = await prisma.billTemplate.findMany({
    where: { userId, isActive: true },
  });

  const now = new Date();

  // Due dates are date-only values stored at UTC midnight. Anchor every
  // comparison to the user's local calendar date rather than the current
  // instant, so a bill due today is not skipped after 00:00 UTC.
  const todayAnchorUtc = zonedDateAnchorUtc(now, timeZone);
  const endDate = addUtcMonthsClamped(todayAnchorUtc, monthsAhead);
  const created: number[] = [];

  for (const template of templates) {
    const startsOn = new Date(template.startsOn);
    const time = utcTimeOfDay(startsOn);

    if (template.recurrence === 'monthly') {
      const monthDay = template.dayOfMonth ?? startsOn.getUTCDate();
      let year = startsOn.getUTCFullYear();
      let monthIndex = startsOn.getUTCMonth();

      while (true) {
        const occurrence = utcOccurrence(year, monthIndex, monthDay, time);

        // Occurrences only move forward; either bound lets us stop.
        if (occurrence > endDate) break;
        if (template.endsOn && occurrence > template.endsOn) break;

        if (occurrence >= startsOn && occurrence >= todayAnchorUtc) {
          await upsertBillInstance(userId, template, occurrence, created);
        }

        monthIndex += 1;
        if (monthIndex > 11) {
          monthIndex = 0;
          year += 1;
        }
      }
    } else if (template.recurrence === 'weekly') {
      const weekDay = template.dayOfWeek ?? startsOn.getUTCDay();
      const offset = (weekDay - startsOn.getUTCDay() + 7) % 7;
      let cursor = new Date(startsOn.getTime() + offset * DAY_MS);

      // Jump whole weeks to the current week while preserving the anchor's
      // weekday. The extra step lands on the next occurrence when this week's
      // slot has already passed.
      if (cursor < todayAnchorUtc) {
        const weeks = Math.floor(
          (todayAnchorUtc.getTime() - cursor.getTime()) / (7 * DAY_MS),
        );
        cursor = new Date(cursor.getTime() + weeks * 7 * DAY_MS);
        if (cursor < todayAnchorUtc) {
          cursor = new Date(cursor.getTime() + 7 * DAY_MS);
        }
      }

      while (cursor <= endDate) {
        if (template.endsOn && cursor > template.endsOn) break;

        if (cursor >= todayAnchorUtc) {
          await upsertBillInstance(userId, template, cursor, created);
        }
        cursor = new Date(cursor.getTime() + 7 * DAY_MS);
      }
    } else {
      // One-time bills are real obligations even when back-filled: keep the
      // exact startsOn occurrence and stop.
      if (!template.endsOn || startsOn <= template.endsOn) {
        await upsertBillInstance(userId, template, startsOn, created);
      }
    }
  }

  return created.length;
}

export async function updateOverdueBills(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';
  const now = new Date();

  // A bill is only overdue once its entire local due date has elapsed in the user's timezone.
  const candidates = await prisma.billInstance.findMany({
    where: {
      userId,
      status: 'upcoming',
      dueDate: { lte: now },
    },
    select: { id: true, dueDate: true },
  });

  const overdueIds = candidates
    .filter((bill) => endOfZonedDay(bill.dueDate, timeZone) < now)
    .map((bill) => bill.id);

  if (overdueIds.length === 0) return 0;

  const result = await prisma.billInstance.updateMany({
    where: {
      id: { in: overdueIds },
      status: 'upcoming',
    },
    data: { status: 'overdue' },
  });
  return result.count;
}
