import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { ValidationError } from '../../lib/errors';
import { parseDateOnlyEnd, parseTransactionDate } from '../../lib/transaction-dates';
import { formatZonedDate, startOfZonedDay } from '../../lib/zoned-dates';
import type { PlanningQuery } from './validation';

type PlanningEventKind = 'income' | 'expense' | 'bill';
type PlanningPressure = 'clear' | 'watch' | 'risk';

export interface PlanningEvent {
  date: string;
  amount: string;
  kind: PlanningEventKind;
}

export interface PlanningCalculationInput {
  from: string;
  to: string;
  currentBalance: string;
  minimumBalanceThreshold: string;
  events: PlanningEvent[];
}

export interface PlanningDay {
  date: string;
  income: string;
  expenses: string;
  bills: string;
  net: string;
  projectedBalance: string;
  pressure: PlanningPressure;
}

export interface PlanningOverview {
  from: string;
  to: string;
  currentBalance: string;
  minimumBalanceThreshold: string;
  totalPlannedIncome: string;
  totalPlannedExpenses: string;
  totalUpcomingBills: string;
  projectedClosingBalance: string;
  availableBuffer: string;
  safeToSpendPerDay: string;
  daysInWindow: number;
  status: PlanningPressure;
  calculationNote: string;
  days: PlanningDay[];
}

const DAY_MS = 24 * 60 * 60 * 1000;

function dateKey(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * DAY_MS);
}

function decimal(value: string | number): Decimal {
  return new Decimal(value || 0);
}

function pressureFor(balance: Decimal, threshold: Decimal): PlanningPressure {
  if (balance.lt(0)) return 'risk';
  if (balance.lt(threshold)) return 'watch';
  return 'clear';
}

export function calculatePlanningOverview(input: PlanningCalculationInput): PlanningOverview {
  const from = parseTransactionDate(input.from);
  const to = parseTransactionDate(input.to);
  const threshold = decimal(input.minimumBalanceThreshold);
  const currentBalance = decimal(input.currentBalance);
  const daysInWindow = Math.floor((to.getTime() - from.getTime()) / DAY_MS) + 1;
  const dayKeys = Array.from({ length: daysInWindow }, (_, index) => dateKey(addDays(from, index)));
  const totals = new Map<string, { income: Decimal; expenses: Decimal; bills: Decimal }>();
  for (const key of dayKeys) {
    totals.set(key, { income: new Decimal(0), expenses: new Decimal(0), bills: new Decimal(0) });
  }

  let totalIncome = new Decimal(0);
  let totalExpenses = new Decimal(0);
  let totalBills = new Decimal(0);
  for (const event of input.events) {
    const day = totals.get(event.date);
    if (!day) continue;
    const amount = decimal(event.amount);
    if (event.kind === 'income') {
      day.income = day.income.plus(amount);
      totalIncome = totalIncome.plus(amount);
    } else if (event.kind === 'expense') {
      day.expenses = day.expenses.plus(amount);
      totalExpenses = totalExpenses.plus(amount);
    } else {
      day.bills = day.bills.plus(amount);
      totalBills = totalBills.plus(amount);
    }
  }

  const projectedClosingBalance = currentBalance.plus(totalIncome).minus(totalExpenses).minus(totalBills);
  const availableBuffer = projectedClosingBalance.minus(threshold);
  const safeToSpendPerDay = availableBuffer.gt(0)
    ? availableBuffer.div(daysInWindow)
    : new Decimal(0);

  let runningBalance = currentBalance;
  const days = dayKeys.map((key) => {
    const totalsForDay = totals.get(key)!;
    const net = totalsForDay.income.minus(totalsForDay.expenses).minus(totalsForDay.bills);
    runningBalance = runningBalance.plus(net);
    return {
      date: key,
      income: totalsForDay.income.toFixed(2),
      expenses: totalsForDay.expenses.toFixed(2),
      bills: totalsForDay.bills.toFixed(2),
      net: net.toFixed(2),
      projectedBalance: runningBalance.toFixed(2),
      pressure: pressureFor(runningBalance, threshold),
    };
  });

  const status = pressureFor(projectedClosingBalance, threshold);
  return {
    from: input.from,
    to: input.to,
    currentBalance: currentBalance.toFixed(2),
    minimumBalanceThreshold: threshold.toFixed(2),
    totalPlannedIncome: totalIncome.toFixed(2),
    totalPlannedExpenses: totalExpenses.toFixed(2),
    totalUpcomingBills: totalBills.toFixed(2),
    projectedClosingBalance: projectedClosingBalance.toFixed(2),
    availableBuffer: Decimal.max(availableBuffer, 0).toFixed(2),
    safeToSpendPerDay: safeToSpendPerDay.toFixed(2),
    daysInWindow,
    status,
    calculationNote: 'Safe to spend divides the projected balance above your safety buffer across this planning window. It excludes new discretionary purchases.',
    days,
  };
}

function defaultDateRange(timeZone: string): { from: string; to: string } {
  const start = startOfZonedDay(new Date(), timeZone);
  const end = new Date(start.getTime() + 30 * DAY_MS);
  return { from: formatZonedDate(start, timeZone), to: formatZonedDate(end, timeZone) };
}

export function buildPlanningEvents(
  income: { receivedAt: Date; amount: Decimal | string | number }[],
  expenses: { spentAt: Date; amount: Decimal | string | number }[],
  bills: { dueDate: Date; amount: Decimal | string | number }[],
  now: Date,
  timeZone: string,
  from: string,
): PlanningEvent[] {
  const todayKey = formatZonedDate(startOfZonedDay(now, timeZone), timeZone);
  const targetTodayKey = from > todayKey ? from : todayKey;

  return [
    ...income.map((entry) => ({
      date: formatZonedDate(entry.receivedAt, timeZone),
      amount: entry.amount.toString(),
      kind: 'income' as const,
    })),
    ...expenses.map((entry) => ({
      date: formatZonedDate(entry.spentAt, timeZone),
      amount: entry.amount.toString(),
      kind: 'expense' as const,
    })),
    ...bills.map((bill) => {
      const billKey = formatZonedDate(bill.dueDate, timeZone);
      const isPastOrToday = bill.dueDate <= now || billKey < from;
      return {
        date: isPastOrToday ? targetTodayKey : billKey,
        amount: bill.amount.toString(),
        kind: 'bill' as const,
      };
    }),
  ];
}

export async function getPlanningOverview(userId: string, query: PlanningQuery): Promise<PlanningOverview> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true, minimumBalanceThreshold: true },
  });
  const range = defaultDateRange(user?.timezone ?? 'UTC');
  const from = query.from ?? range.from;
  const to = query.to ?? range.to;

  // Validate the resolved window (defaults included) so a one-sided query
  // cannot produce an inverted range or a negative safe-to-spend divisor.
  const windowMs =
    parseTransactionDate(to).getTime() - parseTransactionDate(from).getTime();
  if (windowMs < 0) {
    throw new ValidationError(
      'The end date must be on or after the start date',
      { to: 'The end date must be on or after the start date' },
    );
  }
  if (windowMs > 90 * DAY_MS) {
    throw new ValidationError('Planning windows cannot exceed 91 days', {
      to: 'Planning windows cannot exceed 91 days',
    });
  }

  const now = new Date();
  const rangeEnd = parseDateOnlyEnd(to);

  const [snapshot, income, expenses, bills] = await Promise.all([
    import('../forecasting/service').then((forecasting) => forecasting.computeSnapshot(userId)),
    prisma.incomeEntry.findMany({
      where: { userId, status: { in: ['posted', 'planned'] }, receivedAt: { gt: now, lte: rangeEnd } },
      select: { receivedAt: true, amount: true },
    }),
    prisma.expenseEntry.findMany({
      where: { userId, status: { in: ['posted', 'planned'] }, spentAt: { gt: now, lte: rangeEnd } },
      select: { spentAt: true, amount: true },
    }),
    prisma.billInstance.findMany({
      where: { userId, status: { in: ['upcoming', 'overdue'] }, dueDate: { lte: rangeEnd } },
      select: { dueDate: true, amount: true },
    }),
  ]);

  const timeZone = user?.timezone ?? 'UTC';
  const events = buildPlanningEvents(income, expenses, bills, now, timeZone, from);

  return calculatePlanningOverview({
    from,
    to,
    currentBalance: snapshot.actualBalance,
    minimumBalanceThreshold: user?.minimumBalanceThreshold?.toString() ?? '0',
    events,
  });
}
