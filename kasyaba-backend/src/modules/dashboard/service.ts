import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { logger } from '../../lib/logger';
import { toDecimalOrZero } from '../../lib/decimal';
import { withUserResponseCache } from '../../lib/user-cache';
import { endOfZonedMonth, formatZonedDate, startOfZonedMonth } from '../../lib/zoned-dates';
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

  // Resolve user timezone once for all month-bounded queries
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';
  const monthStart = startOfZonedMonth(now, timeZone);
  const monthEnd = endOfZonedMonth(now, timeZone);

  // Fetch forecast and all dashboard sections concurrently
  const [
    forecast,
    upcomingBills,
    goals,
    alerts,
    dailySnapshots,
    budgets,
    categoryExpenses,
  ] = await Promise.all([
    forecastingService.computeSnapshot(userId, timeZone),
    prisma.billInstance.findMany({
      where: {
        userId,
        status: 'upcoming',
        dueDate: { gte: now },
      },
      orderBy: { dueDate: 'asc' },
      take: 5,
    }),
    prisma.savingsGoal.findMany({
      where: { userId, status: 'active' },
      take: 5,
    }),
    prisma.financialAlert.findMany({
      where: { userId, readAt: null, dismissedAt: null, resolvedAt: null },
      orderBy: { createdAt: 'desc' },
      take: 5,
    }),
    prisma.financialSnapshot.findMany({
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
    }),
    prisma.budget.findMany({
      where: {
        userId,
        isActive: true,
        startsOn: { lte: monthEnd },
        OR: [{ endsOn: null }, { endsOn: { gte: monthStart } }],
      },
    }),
    prisma.expenseEntry.groupBy({
      by: ['categoryId'],
      where: { userId, status: 'posted', spentAt: { gte: monthStart, lte: now } },
      _sum: { amount: true },
    }),
  ]);

  // Keep the chart snapshot in step with the cards asynchronously without blocking response
  void forecastingService.createDailySnapshot(userId, forecast, timeZone).catch((err) => {
    logger.warn({ err, userId }, 'Failed to record daily financial snapshot asynchronously');
  });

  const categoryIds = categoryExpenses.map((c) => c.categoryId);
  const categories = categoryIds.length > 0
    ? await prisma.expenseCategory.findMany({
        where: {
          id: { in: categoryIds },
          OR: [{ userId }, { userId: null }],
        },
      })
    : [];

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

  const catMap = new Map(categories.map((c) => [c.id, c]));

  const expensesByCategory = categoryExpenses.map((ce) => ({
    categoryId: ce.categoryId,
    categoryName: catMap.get(ce.categoryId)?.name || 'Unknown',
    iconKey: catMap.get(ce.categoryId)?.iconKey || 'receipt',
    total: toDecimalOrZero(ce._sum.amount).toFixed(2),
  }));

  // Daily balance chart data (last 30 days) formatted in user's timezone
  const dailyBalance = dailySnapshots.map((s) => ({
    date: formatZonedDate(s.snapshotDate, timeZone),
    balance: s.actualBalance.toString(),
    predictedEnd: s.predictedMonthEndBalance.toString(),
  }));

  // Ensure current day is present and up to date on chart using the same timezone
  const todayStr = formatZonedDate(now, timeZone);
  const lastEntry = dailyBalance[dailyBalance.length - 1];
  if (lastEntry && lastEntry.date === todayStr) {
    lastEntry.balance = forecast.actualBalance.toString();
    lastEntry.predictedEnd = forecast.predictedMonthEndBalance.toString();
  } else {
    dailyBalance.push({
      date: todayStr,
      balance: forecast.actualBalance.toString(),
      predictedEnd: forecast.predictedMonthEndBalance.toString(),
    });
  }

  return {
    asOf: now.toISOString(),
    balance: forecast.actualBalance,
    income: forecast.incomeMonthToDate,
    expenses: forecast.expensesMonthToDate,
    savings: forecast.savingsMonthToDate,
    budgetUsedPercent,
    predictedMonthEndBalance: forecast.predictedMonthEndBalance,
    projectedMonthEndIncome: forecast.projectedMonthEndIncome,
    projectedMonthEndExpenses: forecast.projectedMonthEndExpenses,
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
