import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { NotFoundError, ValidationError } from '../../lib/errors';
import { endOfZonedMonth, startOfZonedMonth } from '../../lib/zoned-dates';
import type { CreateBudgetInput, UpdateBudgetInput } from './validation';

export async function listBudgets(userId: string) {
  return prisma.budget.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
}

async function assertCategoryOwned(userId: string, categoryId: string) {
  const category = await prisma.expenseCategory.findFirst({
    where: { id: categoryId, isArchived: false, OR: [{ userId }, { userId: null }] },
    select: { id: true },
  });
  if (!category) throw new NotFoundError('Category not found');
}

export async function createBudget(userId: string, input: CreateBudgetInput) {
  if (input.categoryId) await assertCategoryOwned(userId, input.categoryId);
  return prisma.budget.create({
    data: {
      userId,
      categoryId: input.categoryId || null,
      period: input.period,
      amount: input.amount,
      startsOn: new Date(input.startsOn),
      endsOn: input.endsOn ? new Date(input.endsOn) : null,
      isActive: input.isActive,
    },
  });
}

export async function updateBudget(userId: string, id: string, input: UpdateBudgetInput) {
  const existing = await prisma.budget.findFirst({ where: { id, userId } });
  if (!existing) throw new NotFoundError('Budget not found');
  if (input.categoryId) await assertCategoryOwned(userId, input.categoryId);

  // Enforce the range against the merged record, not just the patch.
  const nextStartsOn =
    input.startsOn ?? existing.startsOn.toISOString().slice(0, 10);
  const nextEndsOn =
    input.endsOn !== undefined
      ? input.endsOn
      : existing.endsOn
        ? existing.endsOn.toISOString().slice(0, 10)
        : null;
  if (nextEndsOn && nextEndsOn < nextStartsOn) {
    throw new ValidationError(
      'The end date must be on or after the start date',
      { endsOn: 'The end date must be on or after the start date' },
    );
  }

  const data: any = { ...input };
  if (input.startsOn) data.startsOn = new Date(input.startsOn);
  if (input.endsOn !== undefined) data.endsOn = input.endsOn ? new Date(input.endsOn) : null;
  return prisma.budget.update({ where: { id }, data });
}

export async function deleteBudget(userId: string, id: string) {
  const existing = await prisma.budget.findFirst({ where: { id, userId } });
  if (!existing) throw new NotFoundError('Budget not found');
  await prisma.budget.delete({ where: { id } });
}

export async function getBudgetStatus(userId: string, month: string) {
  const [yearStr, monthStr] = month.split('-');
  const year = parseInt(yearStr);
  const monthNum = parseInt(monthStr);
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const anchorDate = new Date(Date.UTC(year, monthNum - 1, 15));
  const timeZone = user?.timezone ?? 'UTC';
  const monthStart = startOfZonedMonth(anchorDate, timeZone);
  const monthEnd = endOfZonedMonth(anchorDate, timeZone);
  const actualThrough = monthEnd < new Date() ? monthEnd : new Date();

  // Get active budgets for this period
  const budgets = await prisma.budget.findMany({
    where: {
      userId,
      isActive: true,
      startsOn: { lte: monthEnd },
      OR: [
        { endsOn: null },
        { endsOn: { gte: monthStart } },
      ],
    },
  });

  // Get total expenses for the month
  const expenseAgg = await prisma.expenseEntry.aggregate({
    where: {
      userId,
      status: 'posted',
      spentAt: { gte: monthStart, lte: actualThrough },
    },
    _sum: { amount: true },
  });

  // Get category breakdown
  const categoryExpenses = await prisma.expenseEntry.groupBy({
    by: ['categoryId'],
    where: {
      userId,
      status: 'posted',
      spentAt: { gte: monthStart, lte: actualThrough },
    },
    _sum: { amount: true },
  });

  const totalExpenses = new Decimal(expenseAgg._sum.amount?.toString() ?? 0);

  const categoryTotals = new Map<string, Decimal>();
  for (const ce of categoryExpenses) {
    categoryTotals.set(ce.categoryId, new Decimal(ce._sum.amount?.toString() ?? 0));
  }

  const statuses = budgets.map((budget) => {
    const spent = budget.categoryId
      ? (categoryTotals.get(budget.categoryId) ?? new Decimal(0))
      : totalExpenses;
    const budgetAmount = new Decimal(budget.amount.toString());
    const percentUsed = budgetAmount.gt(0)
      ? spent.div(budgetAmount).mul(100).toDecimalPlaces(1).toNumber()
      : 0;
    const remaining = budgetAmount.minus(spent);

    return {
      budgetId: budget.id,
      categoryId: budget.categoryId,
      amount: budgetAmount.toFixed(2),
      spent: spent.toFixed(2),
      remaining: remaining.toFixed(2),
      percentUsed,
      status: percentUsed >= 100 ? 'exceeded' : percentUsed >= 90 ? 'warning' : 'on_track',
    };
  });

  const totalBudget = budgets.reduce(
    (sum, b) => sum.plus(b.amount.toString()),
    new Decimal(0),
  );

  return {
    month,
    totalBudget: totalBudget.toFixed(2),
    totalSpent: totalExpenses.toFixed(2),
    overallPercent: totalBudget.gt(0)
      ? totalExpenses.div(totalBudget).mul(100).toDecimalPlaces(1).toNumber()
      : 0,
    budgetCount: budgets.length,
    budgets: statuses,
  };
}
