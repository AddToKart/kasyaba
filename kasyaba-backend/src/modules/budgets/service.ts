import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import type { CreateBudgetInput, UpdateBudgetInput } from './validation';

export async function listBudgets(userId: string) {
  return prisma.budget.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
  });
}

export async function createBudget(userId: string, input: CreateBudgetInput) {
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
  const monthStart = new Date(year, monthNum - 1, 1);
  const monthEnd = new Date(year, monthNum, 0, 23, 59, 59, 999);

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
      spentAt: { gte: monthStart, lte: monthEnd },
    },
    _sum: { amount: true },
  });

  // Get category breakdown
  const categoryExpenses = await prisma.expenseEntry.groupBy({
    by: ['categoryId'],
    where: {
      userId,
      spentAt: { gte: monthStart, lte: monthEnd },
    },
    _sum: { amount: true },
  });

  const totalExpenses = Number(expenseAgg._sum.amount) || 0;

  const categoryTotals = new Map<string, number>();
  for (const ce of categoryExpenses) {
    categoryTotals.set(ce.categoryId, Number(ce._sum.amount) || 0);
  }

  const statuses = budgets.map((budget) => {
    const spent = budget.categoryId ? (categoryTotals.get(budget.categoryId) || 0) : totalExpenses;
    const budgetAmount = Number(budget.amount);
    const percentUsed = budgetAmount > 0 ? (spent / budgetAmount) * 100 : 0;
    const remaining = budgetAmount - spent;

    return {
      budgetId: budget.id,
      categoryId: budget.categoryId,
      amount: budget.amount.toString(),
      spent: spent.toFixed(2),
      remaining: remaining.toFixed(2),
      percentUsed: Math.round(percentUsed * 10) / 10,
      status: percentUsed >= 100 ? 'exceeded' : percentUsed >= 90 ? 'warning' : 'on_track',
    };
  });

  return {
    month,
    totalBudget: budgets.reduce((s, b) => s + Number(b.amount), 0).toFixed(2),
    totalSpent: totalExpenses.toFixed(2),
    overallPercent: budgets.length > 0
      ? Math.round((totalExpenses / budgets.reduce((s, b) => s + Number(b.amount), 0)) * 1000) / 10
      : 0,
    budgetCount: budgets.length,
    budgets: statuses,
  };
}
