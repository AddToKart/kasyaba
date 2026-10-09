import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { toDecimalOrZero } from '../../lib/decimal';
import { withUserResponseCache } from '../../lib/user-cache';
import { endOfZonedMonth, startOfZonedMonth } from '../../lib/zoned-dates';
import * as forecastingService from '../forecasting/service';

export function getDashboard(userId: string, period = 'month') {
  // The dashboard is expensive (forecast calculation + snapshot write) and is
  // polled by clients. Cache the response briefly; the app-level mutation
  // middleware clears it on every successful write.
  return withUserResponseCache(`dashboard:${userId}`, () =>
    buildDashboard(userId, period),
  );
}

async function buildDashboard(userId: string, _period = 'month') {
  const now = new Date();
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';
  const monthStart = startOfZonedMonth(now, timeZone);
  const monthEnd = endOfZonedMonth(now, timeZone);

  // Recompute fresh forecast
  const forecast = await forecastingService.computeSnapshot(userId);
  // Keep the chart snapshot in step with the cards after every transaction.
  await forecastingService.createDailySnapshot(userId, forecast);

  // Get upcoming bills
  const upcomingBills = await prisma.billInstance.findMany({
    where: {
      userId,
      status: 'upcoming',
      dueDate: { gte: now },
    },
    orderBy: { dueDate: 'asc' },
    take: 5,
  });

  // Get active goals with progress
  const goals = await prisma.savingsGoal.findMany({
    where: { userId, status: 'active' },
    take: 5,
  });

  // Get unread alerts
  const alerts = await prisma.financialAlert.findMany({
    where: { userId, readAt: null, dismissedAt: null, resolvedAt: null },
    orderBy: { createdAt: 'desc' },
    take: 5,
  });

  // Budget usage
  const budgets = await prisma.budget.findMany({
    where: {
      userId,
      isActive: true,
      startsOn: { lte: monthEnd },
      OR: [{ endsOn: null }, { endsOn: { gte: monthStart } }],
    },
  });

  // Category breakdown for charts
  const categoryExpenses = await prisma.expenseEntry.groupBy({
    by: ['categoryId'],
    where: { userId, status: { in: ['posted', 'planned'] }, spentAt: { gte: monthStart, lte: now } },
    _sum: { amount: true },
  });

  // Use one consistent budget mode: a global budget measures all spending;
  // category budgets measure only the categories that have a budget. This
  // keeps the dashboard aligned with the budget detail screen.
  const globalBudgets = budgets.filter((budget) => budget.categoryId == null);
  const categoryBudgets = budgets.filter((budget) => budget.categoryId != null);
  const budgetPool = globalBudgets.length > 0 ? globalBudgets : categoryBudgets;
  const totalBudgetAmount = budgetPool.reduce(
    (sum, budget) => sum.plus(toDecimalOrZero(budget.amount)),
    new Decimal(0),
  );
  const categoryTotals = new Map(
    categoryExpenses.map((entry) => [
      entry.categoryId,
      toDecimalOrZero(entry._sum.amount),
    ]),
  );
  const budgetedSpend = globalBudgets.length > 0
    ? toDecimalOrZero(forecast.expensesMonthToDate)
    : categoryBudgets.reduce(
        (sum, budget) => sum.plus(categoryTotals.get(budget.categoryId!) ?? 0),
        new Decimal(0),
      );
  const budgetUsedPercent = totalBudgetAmount.gt(0)
    ? budgetedSpend.div(totalBudgetAmount).times(1000).round().div(10).toNumber()
    : 0;

  const categoryIds = categoryExpenses.map((c) => c.categoryId);
  const categories = await prisma.expenseCategory.findMany({
    where: {
      id: { in: categoryIds },
      OR: [{ userId }, { userId: null }],
    },
  });
  const catMap = new Map(categories.map((c) => [c.id, c]));

  const expensesByCategory = categoryExpenses.map((ce) => ({
    categoryId: ce.categoryId,
    categoryName: catMap.get(ce.categoryId)?.name || 'Unknown',
    iconKey: catMap.get(ce.categoryId)?.iconKey || 'receipt',
    total: toDecimalOrZero(ce._sum.amount).toFixed(2),
  }));

  // Daily balance chart data (last 30 days)
  const dailySnapshots = await prisma.financialSnapshot.findMany({
    where: {
      userId,
      snapshotDate: { gte: new Date(now.getTime() - 30 * 86400000) },
    },
    orderBy: { snapshotDate: 'asc' },
    select: {
      snapshotDate: true,
      actualBalance: true,
      predictedMonthEndBalance: true,
    },
  });

  const dailyBalance = dailySnapshots.map((s) => ({
    date: s.snapshotDate.toISOString().split('T')[0],
    balance: s.actualBalance.toString(),
    predictedEnd: s.predictedMonthEndBalance.toString(),
  }));

  return {
    asOf: now.toISOString(),
    balance: forecast.actualBalance,
    income: forecast.incomeMonthToDate,
    expenses: forecast.expensesMonthToDate,
    savings: forecast.savingsMonthToDate,
    budgetUsedPercent,
    predictedMonthEndBalance: forecast.predictedMonthEndBalance,
    healthScore: forecast.healthScore,
    healthGrade: forecast.healthGrade,
    confidence: forecast.confidence,
    upcomingBills: upcomingBills.map((b) => ({
      id: b.id,
      name: b.name,
      amount: toDecimalOrZero(b.amount).toFixed(2),
      dueDate: b.dueDate.toISOString().split('T')[0],
      status: b.status,
    })),
    goals: goals.map((g) => ({
      id: g.id,
      name: g.name,
      targetAmount: toDecimalOrZero(g.targetAmount).toFixed(2),
      targetDate: g.targetDate?.toISOString().split('T')[0],
      status: g.status,
    })),
    alerts: alerts.map((a) => ({
      id: a.id,
      type: a.type,
      severity: a.severity,
      title: a.title,
      message: a.message,
      createdAt: a.createdAt.toISOString(),
    })),
    charts: {
      dailyBalance,
      expensesByCategory,
    },
  };
}
