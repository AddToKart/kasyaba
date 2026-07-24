import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { startOfMonth, endOfMonth, daysInMonth, daysBetween } from '../../lib/dates';
import * as alertService from '../alerts/service';

type Confidence = 'high' | 'medium' | 'low';
type HealthGrade = 'Excellent' | 'Good' | 'Fair' | 'Needs Attention';

interface ForecastResult {
  actualBalance: string;
  incomeMonthToDate: string;
  expensesMonthToDate: string;
  savingsMonthToDate: string;
  projectedMonthEndIncome: string;
  projectedMonthEndExpenses: string;
  predictedMonthEndBalance: string;
  healthScore: number | null;
  healthGrade: string | null;
  confidence: Confidence;
  calculationDetails: Record<string, any>;
}

export async function computeSnapshot(userId: string): Promise<ForecastResult> {
  const now = new Date();
  const monthStart = startOfMonth(now);
  const monthEnd = endOfMonth(now);
  const elapsedDays = daysBetween(monthStart, now);
  const totalDays = daysInMonth(now);
  const remainingDays = totalDays - elapsedDays;

  // --- 1. Actual data this month ---
  const incomeAgg = await prisma.incomeEntry.aggregate({
    where: { userId, receivedAt: { gte: monthStart, lte: monthEnd } },
    _sum: { amount: true },
  });
  const expenseAgg = await prisma.expenseEntry.aggregate({
    where: { userId, spentAt: { gte: monthStart, lte: monthEnd } },
    _sum: { amount: true },
  });

  const incomeMTD = new Decimal(Number(incomeAgg._sum.amount) || 0);
  const expensesMTD = new Decimal(Number(expenseAgg._sum.amount) || 0);

  // --- 2. Actual balance ---
  const accounts = await prisma.financialAccount.findMany({
    where: { userId, isArchived: false },
  });

  const accountBalances = await Promise.all(
    accounts.map(async (acc) => {
      const incAgg = await prisma.incomeEntry.aggregate({
        where: { accountId: acc.id },
        _sum: { amount: true },
      });
      const expAgg = await prisma.expenseEntry.aggregate({
        where: { accountId: acc.id },
        _sum: { amount: true },
      });
      return new Decimal(Number(acc.openingBalance))
        .plus(new Decimal(Number(incAgg._sum.amount) || 0))
        .minus(new Decimal(Number(expAgg._sum.amount) || 0));
    })
  );

  const actualBalance = accountBalances.reduce((s, b) => s.plus(b), new Decimal(0));

  // --- 3. Income projection ---
  const incomeHistory = await prisma.incomeEntry.findMany({
    where: {
      userId,
      receivedAt: { gte: new Date(now.getFullYear(), now.getMonth() - 3, 1), lt: monthStart },
    },
    orderBy: { receivedAt: 'desc' },
  });

  // Group income by month for the last 3 months
  const monthlyIncome: { [key: string]: Decimal } = {};
  for (const entry of incomeHistory) {
    const key = `${entry.receivedAt.getFullYear()}-${entry.receivedAt.getMonth()}`;
    monthlyIncome[key] = (monthlyIncome[key] || new Decimal(0)).plus(new Decimal(Number(entry.amount)));
  }

  const monthlyValues = Object.values(monthlyIncome);
  let projectedIncome: Decimal;
  if (monthlyValues.length >= 3) {
    // Weighted average of last 3 months
    projectedIncome = monthlyValues[0]?.times(0.5)
      .plus(monthlyValues[1]?.times(0.3) || new Decimal(0))
      .plus(monthlyValues[2]?.times(0.2) || new Decimal(0));
  } else if (monthlyValues.length > 0) {
    projectedIncome = incomeMTD.gt(0)
      ? incomeMTD.div(elapsedDays || 1).times(totalDays)
      : monthlyValues.reduce((s, v) => s.plus(v), new Decimal(0)).div(monthlyValues.length);
  } else {
    projectedIncome = incomeMTD;
  }

  // --- 4. Expense projection ---
  const expenseHistory = await prisma.expenseEntry.findMany({
    where: {
      userId,
      spentAt: { gte: new Date(now.getFullYear(), now.getMonth() - 3, 1), lt: monthStart },
    },
    orderBy: { spentAt: 'desc' },
  });

  const monthlyExpenses: { [key: string]: Decimal } = {};
  for (const entry of expenseHistory) {
    const key = `${entry.spentAt.getFullYear()}-${entry.spentAt.getMonth()}`;
    monthlyExpenses[key] = (monthlyExpenses[key] || new Decimal(0)).plus(new Decimal(Number(entry.amount)));
  }

  const expMonthlyValues = Object.values(monthlyExpenses);
  let projectedVariableExpenses: Decimal;
  let dataConfidence: Confidence;

  if (expMonthlyValues.length >= 3) {
    projectedVariableExpenses = expMonthlyValues[0]?.times(0.5)
      .plus(expMonthlyValues[1]?.times(0.3) || new Decimal(0))
      .plus(expMonthlyValues[2]?.times(0.2) || new Decimal(0));
    dataConfidence = 'high';
  } else if (expMonthlyValues.length >= 1 || elapsedDays >= 30) {
    const dailyAvg = expensesMTD.div(elapsedDays || 1);
    projectedVariableExpenses = dailyAvg.times(totalDays);
    dataConfidence = 'medium';
  } else {
    projectedVariableExpenses = expensesMTD.div(elapsedDays || 1).times(totalDays);
    dataConfidence = 'low';
  }

  // --- 5. Known upcoming bills ---
  const unpaidBills = await prisma.billInstance.findMany({
    where: {
      userId,
      status: { in: ['upcoming', 'overdue'] },
      dueDate: { gte: now, lte: monthEnd },
    },
  });
  const billsTotal = unpaidBills.reduce(
    (s, b) => s.plus(new Decimal(Number(b.amount))),
    new Decimal(0)
  );

  // --- 6. Projected month end ---
  const projectedMonthEndIncomeVal = incomeMTD.gt(0)
    ? incomeMTD.plus(projectedIncome.minus(incomeMTD))
    : projectedIncome;

  const projectedMonthEndExpensesVal = expensesMTD.plus(
    projectedVariableExpenses.minus(expensesMTD)
  ).plus(billsTotal);

  const predictedMonthEndBalance = actualBalance
    .plus(projectedMonthEndIncomeVal.minus(incomeMTD))
    .minus(projectedMonthEndExpensesVal.minus(expensesMTD));

  // --- 7. Savings ---
  const savingsContribAgg = await prisma.savingsContribution.aggregate({
    where: { userId, contributedAt: { gte: monthStart, lte: monthEnd } },
    _sum: { amount: true },
  });
  const savingsMTD = new Decimal(Number(savingsContribAgg._sum.amount) || 0);

  // --- 8. Health Score ---
  const healthResult = computeHealthScore({
    incomeMTD,
    expensesMTD,
    savingsMTD,
    projectedMonthEndExpenses: projectedMonthEndExpensesVal,
    actualBalance,
    predictedMonthEndBalance,
    userId,
    now,
  });

  // --- 9. Build result ---
  const result: ForecastResult = {
    actualBalance: actualBalance.toFixed(2),
    incomeMonthToDate: incomeMTD.toFixed(2),
    expensesMonthToDate: expensesMTD.toFixed(2),
    savingsMonthToDate: savingsMTD.toFixed(2),
    projectedMonthEndIncome: projectedMonthEndIncomeVal.toFixed(2),
    projectedMonthEndExpenses: projectedMonthEndExpensesVal.toFixed(2),
    predictedMonthEndBalance: predictedMonthEndBalance.toFixed(2),
    healthScore: healthResult.score,
    healthGrade: healthResult.grade,
    confidence: dataConfidence,
    calculationDetails: {
      version: '1.0.0',
      confidence: dataConfidence,
      elapsedDays,
      totalDays,
      monthlyIncomeHistory: monthlyValues.map((v) => v.toFixed(2)),
      monthlyExpenseHistory: expMonthlyValues.map((v) => v.toFixed(2)),
      unpaidBillsCount: unpaidBills.length,
      unpaidBillsTotal: billsTotal.toFixed(2),
      savingsRate: incomeMTD.gt(0) ? savingsMTD.div(incomeMTD).times(100).toFixed(2) : '0.00',
    },
  };

  return result;
}

export async function createDailySnapshot(userId: string): Promise<void> {
  const result = await computeSnapshot(userId);
  const now = new Date();
  const snapshotDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  await prisma.financialSnapshot.upsert({
    where: {
      userId_snapshotDate: { userId, snapshotDate },
    },
    update: {
      actualBalance: result.actualBalance,
      incomeMonthToDate: result.incomeMonthToDate,
      expensesMonthToDate: result.expensesMonthToDate,
      savingsMonthToDate: result.savingsMonthToDate,
      projectedMonthEndIncome: result.projectedMonthEndIncome,
      projectedMonthEndExpenses: result.projectedMonthEndExpenses,
      predictedMonthEndBalance: result.predictedMonthEndBalance,
      healthScore: result.healthScore,
      healthGrade: result.healthGrade,
      calculationVersion: '1.0.0',
      calculationDetails: result.calculationDetails,
    },
    create: {
      userId,
      snapshotDate,
      actualBalance: result.actualBalance,
      incomeMonthToDate: result.incomeMonthToDate,
      expensesMonthToDate: result.expensesMonthToDate,
      savingsMonthToDate: result.savingsMonthToDate,
      projectedMonthEndIncome: result.projectedMonthEndIncome,
      projectedMonthEndExpenses: result.projectedMonthEndExpenses,
      predictedMonthEndBalance: result.predictedMonthEndBalance,
      healthScore: result.healthScore,
      healthGrade: result.healthGrade,
      calculationVersion: '1.0.0',
      calculationDetails: result.calculationDetails,
    },
  });
}

export async function generateAlertsFromSnapshot(userId: string): Promise<void> {
  const now = new Date();
  const monthStart = startOfMonth(now);
  const monthEnd = endOfMonth(now);
  const snapshot = await prisma.financialSnapshot.findFirst({
    where: { userId, snapshotDate: { gte: monthStart } },
    orderBy: { snapshotDate: 'desc' },
  });
  if (!snapshot) return;

  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;

  // --- Budget Overrun Alert ---
  const budgets = await prisma.budget.findMany({
    where: { userId, isActive: true, startsOn: { lte: monthEnd } },
  });

  for (const budget of budgets) {
    const budgetAmount = Number(budget.amount);
    const projectedSpend = Number(snapshot.projectedMonthEndExpenses);
    const percentUsed = budgetAmount > 0 ? (projectedSpend / budgetAmount) * 100 : 0;

    let severity: 'info' | 'warning' | 'critical' = 'info';
    if (percentUsed > 115) severity = 'critical';
    else if (percentUsed > 100) severity = 'warning';
    else if (percentUsed > 90) severity = 'info';
    else continue; // No alert needed

    const dedupKey = `${userId}:budget_overrun:${now.getFullYear()}-${now.getMonth()}:${budget.id}`;

    await alertService.createAlert({
      userId,
      snapshotId: snapshot.id,
      type: 'budget_overrun',
      severity,
      title: severity === 'critical' ? 'Budget significantly overrun' : 'Budget nearly exceeded',
      message: `Your projected month-end spending (₱${projectedSpend.toFixed(2)}) is at ${percentUsed.toFixed(1)}% of your budget (₱${budgetAmount.toFixed(2)}).`,
      reasonData: { budgetAmount, projectedSpend, percentUsed: Math.round(percentUsed * 10) / 10 },
      effectiveDate: now,
      deduplicationKey: dedupKey,
    });
  }

  // --- Low Balance Alert ---
  const minThreshold = Number(user.minimumBalanceThreshold);
  const projectedBalance = Number(snapshot.predictedMonthEndBalance);

  if (projectedBalance < minThreshold) {
    const unpaidBills = await prisma.billInstance.findMany({
      where: {
        userId,
        status: { in: ['upcoming', 'overdue'] },
        dueDate: { gte: now },
      },
      orderBy: { dueDate: 'asc' },
      take: 5,
    });

    const billsInfo = unpaidBills.map((b) => ({
      name: b.name,
      amount: Number(b.amount).toFixed(2),
      dueDate: b.dueDate.toISOString().split('T')[0],
    }));

    const key = `${userId}:low_balance:${now.getFullYear()}-${now.getMonth()}`;
    await alertService.createAlert({
      userId,
      snapshotId: snapshot.id,
      type: 'low_balance',
      severity: projectedBalance < 0 ? 'critical' : 'warning',
      title: projectedBalance < 0 ? 'Possible negative balance' : 'Low balance warning',
      message: `Your projected month-end balance is ₱${projectedBalance.toFixed(2)}. This is below your ₱${minThreshold.toFixed(2)} threshold.`,
      reasonData: { projectedBalance, minThreshold, upcomingBills: billsInfo },
      effectiveDate: now,
      deduplicationKey: key,
    });
  } else {
    // Resolve if no longer low
    await alertService.resolveAlertsByKey(userId, `${userId}:low_balance:`);
  }

  // --- Month-end forecast alert ---
  if (projectedBalance < 0) {
    const key = `${userId}:month_end:${now.getFullYear()}-${now.getMonth()}`;
    await alertService.createAlert({
      userId,
      snapshotId: snapshot.id,
      type: 'month_end',
      severity: 'warning',
      title: 'Month-end deficit predicted',
      message: `Your predicted month-end balance is ₱${projectedBalance.toFixed(2)}. Review your spending to avoid a deficit.`,
      reasonData: { predictedMonthEndBalance: projectedBalance },
      effectiveDate: now,
      deduplicationKey: key,
    });
  }

  // --- Savings Goal Alert ---
  const goals = await prisma.savingsGoal.findMany({
    where: { userId, status: 'active' },
  });

  for (const goal of goals) {
    if (!goal.targetDate) continue;

    const agg = await prisma.savingsContribution.aggregate({
      where: { goalId: goal.id },
      _sum: { amount: true },
    });
    const totalContributed = Number(agg._sum.amount) || 0;
    const targetAmount = Number(goal.targetAmount);
    const remaining = targetAmount - totalContributed;

    if (remaining <= 0) continue;

    const monthsUntilTarget = daysBetween(now, goal.targetDate) / 30;
    if (monthsUntilTarget <= 0) continue;

    // Check 3-month average contribution pace
    const threeMonthsAgo = new Date();
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);
    const recentAgg = await prisma.savingsContribution.aggregate({
      where: { goalId: goal.id, contributedAt: { gte: threeMonthsAgo } },
      _sum: { amount: true },
    });
    const averageMonthly = (Number(recentAgg._sum.amount) || 0) / 3;

    if (averageMonthly > 0) {
      const neededMonthly = remaining / monthsUntilTarget;
      if (averageMonthly < neededMonthly) {
        const key = `${userId}:savings_goal:${goal.id}`;
        await alertService.createAlert({
          userId,
          snapshotId: snapshot.id,
          type: 'savings_goal',
          severity: (neededMonthly / averageMonthly) > 2 ? 'critical' : 'warning',
          title: 'Savings goal may be delayed',
          message: `Your goal "${goal.name}" needs ₱${neededMonthly.toFixed(2)}/month to stay on track, but you're contributing ₱${averageMonthly.toFixed(2)}/month on average.`,
          reasonData: {
            goalName: goal.name,
            targetAmount,
            totalContributed,
            remaining,
            neededMonthly: neededMonthly.toFixed(2),
            averageMonthly: averageMonthly.toFixed(2),
            monthsUntilTarget,
          },
          effectiveDate: now,
          deduplicationKey: key,
        });
      }
    }
  }

  // --- Bill Due Alerts ---
  const upcomingBills = await prisma.billInstance.findMany({
    where: {
      userId,
      status: 'upcoming',
      dueDate: { gte: now, lte: new Date(now.getTime() + 7 * 86400000) },
    },
  });

  for (const bill of upcomingBills) {
    const daysUntilDue = daysBetween(now, bill.dueDate);
    const key = `${userId}:bill_due:${bill.id}`;

    await alertService.createAlert({
      userId,
      snapshotId: snapshot.id,
      type: 'bill_due',
      severity: daysUntilDue <= 1 ? 'warning' : 'info',
      title: `Bill due ${daysUntilDue === 0 ? 'today' : `in ${daysUntilDue} days`}`,
      message: `"${bill.name}" of ₱${Number(bill.amount).toFixed(2)} is due on ${bill.dueDate.toISOString().split('T')[0]}.`,
      reasonData: {
        billName: bill.name,
        amount: Number(bill.amount).toFixed(2),
        dueDate: bill.dueDate.toISOString().split('T')[0],
        daysUntilDue,
      },
      effectiveDate: now,
      deduplicationKey: key,
    });
  }
}

interface HealthInput {
  incomeMTD: Decimal;
  expensesMTD: Decimal;
  savingsMTD: Decimal;
  projectedMonthEndExpenses: Decimal;
  actualBalance: Decimal;
  predictedMonthEndBalance: Decimal;
  userId: string;
  now: Date;
}

interface HealthOutput {
  score: number;
  grade: HealthGrade;
}

function computeHealthScore(input: HealthInput): HealthOutput {
  const { incomeMTD, expensesMTD, savingsMTD } = input;

  // --- Savings score (30%) ---
  let savingsScore = 0;
  const savingsRate = incomeMTD.gt(0) ? Number(savingsMTD.div(incomeMTD)) : 0;
  if (savingsRate >= 0.20) savingsScore = 100;
  else if (savingsRate >= 0.10) savingsScore = 70 + (savingsRate - 0.10) / 0.10 * 29;
  else if (savingsRate > 0) savingsScore = 30 + (savingsRate / 0.10) * 39;
  else savingsScore = 0;

  // --- Budget score (30%) ---
  let budgetScore = 0;
  const budgetTotal = Number(input.projectedMonthEndExpenses);
  const incomeTotal = Number(incomeMTD);
  const budgetRatio = incomeTotal > 0 ? budgetTotal / incomeTotal : 1;

  if (budgetRatio <= 0.90) budgetScore = 100;
  else if (budgetRatio <= 1.00) budgetScore = 70 + (1 - budgetRatio) / 0.10 * 29;
  else if (budgetRatio <= 1.15) budgetScore = 30 + (1.15 - budgetRatio) / 0.15 * 39;
  else budgetScore = Math.max(0, 30 - (budgetRatio - 1.15) / 0.15 * 30);

  // --- Bill reliability score (20%) ---
  let billScore = 50; // Default mid score
  // For MVP, simplified - check overdue bills
  // In production, track payment history over 3 months
  const billScoreVal = 70;

  // --- Balance resilience score (20%) ---
  let resilienceScore = 50;
  const projectedBalance = Number(input.predictedMonthEndBalance);
  if (projectedBalance > 0) {
    resilienceScore = Math.min(100, 50 + (projectedBalance / (incomeTotal || 1)) * 100);
  } else {
    resilienceScore = Math.max(0, 50 + (projectedBalance / (incomeTotal || 1)) * 50);
  }

  // --- Composite ---
  const totalScore = Math.round(
    savingsScore * 0.30 + budgetScore * 0.30 + billScoreVal * 0.20 + resilienceScore * 0.20
  );

  let grade: HealthGrade;
  if (totalScore >= 85) grade = 'Excellent';
  else if (totalScore >= 70) grade = 'Good';
  else if (totalScore >= 50) grade = 'Fair';
  else grade = 'Needs Attention';

  return { score: totalScore, grade };
}
