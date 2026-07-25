import { prisma } from '../../config/database';
import { startOfMonth, endOfMonth } from '../../lib/dates';
import * as forecastingService from '../forecasting/service';

export async function getDashboard(userId: string, _period = 'month') {
  const now = new Date();
  const monthStart = startOfMonth(now);
  const monthEnd = endOfMonth(now);

  // Try to get today's snapshot, or compute one
  const snapshot = await prisma.financialSnapshot.findFirst({
    where: {
      userId,
      snapshotDate: { gte: monthStart },
    },
    orderBy: { snapshotDate: 'desc' },
  });

  // Recompute fresh forecast
  const forecast = await forecastingService.computeSnapshot(userId);

  // If no snapshot exists, create one
  if (!snapshot) {
    await forecastingService.createDailySnapshot(userId);
  }

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
    where: { userId, readAt: null, dismissedAt: null },
    orderBy: { createdAt: 'desc' },
    take: 5,
  });

  // Budget usage
  const budgets = await prisma.budget.findMany({
    where: { userId, isActive: true, startsOn: { lte: monthEnd } },
  });
  const totalBudgetAmount = budgets.reduce((s, b) => s + Number(b.amount), 0);
  const budgetUsedPercent = totalBudgetAmount > 0
    ? Math.round((Number(forecast.expensesMonthToDate) / totalBudgetAmount) * 1000) / 10
    : 0;

  // Category breakdown for charts
  const categoryExpenses = await prisma.expenseEntry.groupBy({
    by: ['categoryId'],
    where: { userId, spentAt: { gte: monthStart, lte: monthEnd } },
    _sum: { amount: true },
  });

  const categoryIds = categoryExpenses.map((c) => c.categoryId);
  const categories = await prisma.expenseCategory.findMany({
    where: { id: { in: categoryIds } },
  });
  const catMap = new Map(categories.map((c) => [c.id, c]));

  const expensesByCategory = categoryExpenses.map((ce) => ({
    categoryId: ce.categoryId,
    categoryName: catMap.get(ce.categoryId)?.name || 'Unknown',
    iconKey: catMap.get(ce.categoryId)?.iconKey || 'receipt',
    total: Number(ce._sum.amount).toFixed(2),
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
      amount: Number(b.amount).toFixed(2),
      dueDate: b.dueDate.toISOString().split('T')[0],
      status: b.status,
    })),
    goals: goals.map((g) => ({
      id: g.id,
      name: g.name,
      targetAmount: Number(g.targetAmount).toFixed(2),
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
