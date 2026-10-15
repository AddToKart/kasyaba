import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { toDecimalOrZero } from '../../lib/decimal';
import { daysInMonth, daysBetween } from '../../lib/dates';
import { endOfZonedMonth, getZonedParts, startOfZonedDay, startOfZonedMonth } from '../../lib/zoned-dates';
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
  healthScore: number;
  healthGrade: HealthGrade;
  confidence: Confidence;
  calculationDetails: Record<string, any>;
}

export async function computeSnapshot(
  userId: string,
  providedTimeZone?: string,
): Promise<ForecastResult> {
  const now = new Date();
  const timeZone: string =
    providedTimeZone ??
    ((await prisma.user
      .findUnique({
        where: { id: userId },
        select: { timezone: true },
      })
      .then((u) => u?.timezone ?? 'UTC')) ?? 'UTC');
  const monthStart = startOfZonedMonth(now, timeZone);
  const monthEnd = endOfZonedMonth(now, timeZone);
  const elapsedDays = daysBetween(monthStart, now);
  const totalDays = daysInMonth(now);
  const threeMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 3, 1);

  // --- 1. Fetch all independent user data concurrently in Batch 1 ---
  const [
    [incomeAgg, expenseAgg, scheduledIncomeAgg, scheduledExpenseAgg],
    accounts,
    billExpenses,
    incomeHistory,
    unpaidBills,
    savingsContribAgg,
    [paidBills, totalBills],
  ] = await Promise.all([
    Promise.all([
      prisma.incomeEntry.aggregate({
        where: { userId, status: { in: ['posted', 'planned'] }, receivedAt: { gte: monthStart, lte: now } },
        _sum: { amount: true },
      }),
      prisma.expenseEntry.aggregate({
        where: { userId, status: { in: ['posted', 'planned'] }, spentAt: { gte: monthStart, lte: now } },
        _sum: { amount: true },
      }),
      prisma.incomeEntry.aggregate({
        where: { userId, status: 'planned', receivedAt: { gt: now, lte: monthEnd } },
        _sum: { amount: true },
      }),
      prisma.expenseEntry.aggregate({
        where: { userId, status: 'planned', spentAt: { gt: now, lte: monthEnd } },
        _sum: { amount: true },
      }),
    ]),
    prisma.financialAccount.findMany({
      where: { userId },
      select: { id: true, openingBalance: true },
    }),
    prisma.billInstance.findMany({
      where: { userId, expenseEntryId: { not: null } },
      select: { expenseEntryId: true },
    }),
    prisma.incomeEntry.findMany({
      where: {
        userId,
        status: { in: ['posted', 'planned'] },
        receivedAt: { gte: threeMonthsAgo, lt: monthStart },
      },
      orderBy: { receivedAt: 'desc' },
    }),
    prisma.billInstance.findMany({
      where: {
        userId,
        status: { in: ['upcoming', 'overdue'] },
        dueDate: { lte: monthEnd },
      },
    }),
    prisma.savingsContribution.aggregate({
      where: { userId, contributedAt: { gte: monthStart, lte: now } },
      _sum: { amount: true },
    }),
    Promise.all([
      prisma.billInstance.count({
        where: {
          userId,
          status: 'paid',
          dueDate: { gte: threeMonthsAgo, lte: now },
        },
      }),
      prisma.billInstance.count({
        where: {
          userId,
          status: { in: ['paid', 'overdue', 'cancelled'] },
          dueDate: { gte: threeMonthsAgo, lte: now },
        },
      }),
    ]),
  ]);

  const incomeMTD = toDecimalOrZero(incomeAgg._sum.amount);
  const expensesMTD = toDecimalOrZero(expenseAgg._sum.amount);
  const scheduledIncome = toDecimalOrZero(scheduledIncomeAgg._sum.amount);
  const scheduledExpenses = toDecimalOrZero(scheduledExpenseAgg._sum.amount);
  const accountIds = accounts.map((a) => a.id);
  const billExpenseIds = billExpenses.map((b) => b.expenseEntryId!).filter(Boolean);

  // --- 2. Batch 2: Account groupBys (skipped if no accounts) & expense history ---
  const expenseHistoryWhere: any = {
    userId,
    status: { in: ['posted', 'planned'] },
    spentAt: { gte: threeMonthsAgo, lt: monthStart },
  };
  if (billExpenseIds.length > 0) {
    expenseHistoryWhere.id = { notIn: billExpenseIds };
  }

  const [
    [incByAccount, expByAccount, savingsByAccount, outgoingByAccount, incomingByAccount],
    expenseHistory,
    billsPaidMTDAgg,
  ] = await Promise.all([
    accountIds.length === 0
      ? Promise.resolve([[], [], [], [], []])
      : Promise.all([
          prisma.incomeEntry.groupBy({
            by: ['accountId'],
            where: { userId, accountId: { in: accountIds }, status: { in: ['posted', 'planned'] }, receivedAt: { lte: now } },
            _sum: { amount: true },
          }),
          prisma.expenseEntry.groupBy({
            by: ['accountId'],
            where: { userId, accountId: { in: accountIds }, status: { in: ['posted', 'planned'] }, spentAt: { lte: now } },
            _sum: { amount: true },
          }),
          prisma.savingsContribution.groupBy({
            by: ['accountId'],
            where: { userId, accountId: { in: accountIds }, contributedAt: { lte: now } },
            _sum: { amount: true },
          }),
          prisma.accountTransfer.groupBy({
            by: ['fromAccountId'],
            where: { userId, fromAccountId: { in: accountIds }, status: { in: ['posted', 'planned'] }, transferredAt: { lte: now } },
            _sum: { amount: true },
          }),
          prisma.accountTransfer.groupBy({
            by: ['toAccountId'],
            where: { userId, toAccountId: { in: accountIds }, status: { in: ['posted', 'planned'] }, transferredAt: { lte: now } },
            _sum: { amount: true },
          }),
        ]),
    prisma.expenseEntry.findMany({
      where: expenseHistoryWhere,
      orderBy: { spentAt: 'desc' },
    }),
    billExpenseIds.length === 0
      ? Promise.resolve({ _sum: { amount: null } })
      : prisma.expenseEntry.aggregate({
          where: {
            userId,
            id: { in: billExpenseIds },
            status: { in: ['posted', 'planned'] },
            spentAt: { gte: monthStart, lte: now },
          },
          _sum: { amount: true },
        }),
  ]);

  const billsPaidMTD = toDecimalOrZero(billsPaidMTDAgg._sum.amount);
  const variableExpensesMTD = Decimal.max(0, expensesMTD.minus(billsPaidMTD));

  const incMap = new Map(incByAccount.map((r) => [r.accountId, toDecimalOrZero(r._sum.amount)]));
  const expMap = new Map(expByAccount.map((r) => [r.accountId, toDecimalOrZero(r._sum.amount)]));
  const savingsMap = new Map(savingsByAccount.map((r) => [r.accountId, toDecimalOrZero(r._sum.amount)]));
  const outgoingMap = new Map(outgoingByAccount.map((r) => [r.fromAccountId, toDecimalOrZero(r._sum.amount)]));
  const incomingMap = new Map(incomingByAccount.map((r) => [r.toAccountId, toDecimalOrZero(r._sum.amount)]));

  const actualBalance = accounts.reduce((s, acc) => {
    return s.plus(toDecimalOrZero(acc.openingBalance))
      .plus(incMap.get(acc.id) ?? 0)
      .minus(expMap.get(acc.id) ?? 0)
      .minus(savingsMap.get(acc.id) ?? 0)
      .minus(outgoingMap.get(acc.id) ?? 0)
      .plus(incomingMap.get(acc.id) ?? 0);
  }, new Decimal(0));

  // --- 3. Income projection ---
  const monthlyIncome: { [key: string]: Decimal } = {};
  for (const entry of incomeHistory) {
    const key = `${entry.receivedAt.getFullYear()}-${entry.receivedAt.getMonth()}`;
    monthlyIncome[key] = (monthlyIncome[key] || new Decimal(0)).plus(toDecimalOrZero(entry.amount));
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
  const monthlyExpenses: { [key: string]: Decimal } = {};
  for (const entry of expenseHistory) {
    const key = `${entry.spentAt.getFullYear()}-${entry.spentAt.getMonth()}`;
    monthlyExpenses[key] = (monthlyExpenses[key] || new Decimal(0)).plus(toDecimalOrZero(entry.amount));
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
    const dailyAvg = variableExpensesMTD.div(elapsedDays || 1);
    projectedVariableExpenses = dailyAvg.times(totalDays);
    dataConfidence = 'medium';
  } else {
    projectedVariableExpenses = variableExpensesMTD.div(elapsedDays || 1).times(totalDays);
    dataConfidence = 'low';
  }

  // --- 5. Known upcoming bills and total bills for month ---
  const billsTotal = unpaidBills.reduce(
    (s, b) => s.plus(toDecimalOrZero(b.amount)),
    new Decimal(0)
  );
  const totalMonthBills = billsPaidMTD.plus(billsTotal);

  // --- 6. Projected month end ---
  // Known future-dated entries are part of the month-end plan, but not today's
  // actual balance or month-to-date totals. Use the larger of the statistical
  // projection and the explicitly scheduled amount to avoid double-counting a
  // scheduled entry that the projection already covers.
  const knownMonthEndIncome = incomeMTD.plus(scheduledIncome);
  const projectedMonthEndIncomeVal = projectedIncome.gt(knownMonthEndIncome)
    ? projectedIncome
    : knownMonthEndIncome;

  const knownMonthEndVariable = variableExpensesMTD.plus(scheduledExpenses);
  const projectedVariableExpensesVal = projectedVariableExpenses.gt(knownMonthEndVariable)
    ? projectedVariableExpenses
    : knownMonthEndVariable;
  const projectedMonthEndExpensesVal = Decimal.max(
    projectedVariableExpensesVal.plus(totalMonthBills),
    expensesMTD.plus(scheduledExpenses),
  );

  const predictedMonthEndBalance = actualBalance
    .plus(projectedMonthEndIncomeVal.minus(incomeMTD))
    .minus(projectedMonthEndExpensesVal.minus(expensesMTD));

  // --- 7. Savings ---
  const savingsMTD = toDecimalOrZero(savingsContribAgg._sum.amount);

  // --- 8. Bill payment rate (last 3 months) ---
  const billPaymentRate = totalBills > 0 ? paidBills / totalBills : -1;

  // --- 9. Health Score ---
  const healthResult = computeHealthScore({
    incomeMTD,
    expensesMTD,
    savingsMTD,
    projectedMonthEndExpenses: projectedMonthEndExpensesVal,
    projectedMonthEndIncome: projectedMonthEndIncomeVal,
    actualBalance,
    predictedMonthEndBalance,
    userId,
    now,
    billPaymentRate,
  });

  // --- 10. Build result ---
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
      scheduledIncomeThisMonth: scheduledIncome.toFixed(2),
      scheduledExpensesThisMonth: scheduledExpenses.toFixed(2),
      unpaidBillsCount: unpaidBills.length,
      unpaidBillsTotal: billsTotal.toFixed(2),
      savingsRate: incomeMTD.gt(0) ? savingsMTD.div(incomeMTD).times(100).toFixed(2) : '0.00',
    },
  };

  return result;
}

export async function createDailySnapshot(
  userId: string,
  existingResult?: ForecastResult,
  providedTimeZone?: string,
): Promise<void> {
  const result = existingResult ?? await computeSnapshot(userId, providedTimeZone);
  const now = new Date();
  const timeZone: string =
    providedTimeZone ??
    ((await prisma.user
      .findUnique({
        where: { id: userId },
        select: { timezone: true },
      })
      .then((u) => u?.timezone ?? 'UTC')) ?? 'UTC');
  const snapshotDate = startOfZonedDay(now, timeZone);

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
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) return;
  const timeZone = user.timezone ?? 'UTC';
  const monthStart = startOfZonedMonth(now, timeZone);
  const monthEnd = endOfZonedMonth(now, timeZone);
  const snapshot = await prisma.financialSnapshot.findFirst({
    where: { userId, snapshotDate: { gte: monthStart } },
    orderBy: { snapshotDate: 'desc' },
  });
  if (!snapshot) {
    await createDailySnapshot(userId);
  }

  const currentSnapshot = snapshot ?? await prisma.financialSnapshot.findFirst({
    where: { userId, snapshotDate: { gte: monthStart } },
    orderBy: { snapshotDate: 'desc' },
  });
  if (!currentSnapshot) return;

  // --- Budget Overrun Alert ---
  const budgets = await prisma.budget.findMany({
    where: {
      userId,
      isActive: true,
      startsOn: { lte: monthEnd },
      OR: [{ endsOn: null }, { endsOn: { gte: monthStart } }],
    },
  });
  const categoryExpenses = await prisma.expenseEntry.groupBy({
    by: ['categoryId'],
    where: {
      userId,
      status: { in: ['posted', 'planned'] },
      spentAt: { gte: monthStart, lte: now },
    },
    _sum: { amount: true },
  });
  const categoryExpenseTotals = new Map(
    categoryExpenses.map((entry) => [entry.categoryId, toDecimalOrZero(entry._sum.amount)]),
  );
  await alertService.resolveAlertsByKey(userId, `${userId}:budget_overrun:`);

  const elapsedDays = daysBetween(monthStart, now);
  const totalDays = daysInMonth(now);

  for (const budget of budgets) {
    const budgetAmount = toDecimalOrZero(budget.amount);
    let projectedSpend: Decimal;
    if (budget.categoryId) {
      const mtdSpend = categoryExpenseTotals.get(budget.categoryId) ?? new Decimal(0);
      const extrapolated = elapsedDays > 0
        ? mtdSpend.div(elapsedDays).times(totalDays)
        : mtdSpend;
      projectedSpend = Decimal.max(mtdSpend, extrapolated);
    } else {
      projectedSpend = toDecimalOrZero(currentSnapshot.projectedMonthEndExpenses);
    }
    const percentUsed = budgetAmount.gt(0)
      ? projectedSpend.div(budgetAmount).times(100).toNumber()
      : 0;

    if (percentUsed <= 90) continue; // No alert needed
    const severity = percentUsed > 115 ? 'critical' : (percentUsed > 100 ? 'warning' : 'info');

    const dedupKey = `${userId}:budget_overrun:${now.getFullYear()}-${now.getMonth()}:${budget.id}`;

    await alertService.createAlert({
      userId,
      snapshotId: currentSnapshot.id,
      type: 'budget_overrun',
      severity,
      title: severity === 'critical' ? 'Budget significantly overrun' : 'Budget nearly exceeded',
      message: `Your projected month-end spending (₱${projectedSpend.toFixed(2)}) is at ${percentUsed.toFixed(1)}% of your budget (₱${budgetAmount.toFixed(2)}).`,
      reasonData: {
        budgetAmount: budgetAmount.toNumber(),
        projectedSpend: projectedSpend.toNumber(),
        percentUsed: Math.round(percentUsed * 10) / 10,
      },
      effectiveDate: now,
      deduplicationKey: dedupKey,
    });
  }

  // --- Low Balance Alert ---
  const minThreshold = toDecimalOrZero(user.minimumBalanceThreshold);
  const projectedBalance = toDecimalOrZero(currentSnapshot.predictedMonthEndBalance);

  if (projectedBalance.lt(minThreshold)) {
    const unpaidBills = await prisma.billInstance.findMany({
      where: {
        userId,
        status: { in: ['upcoming', 'overdue'] },
        dueDate: { lte: new Date(now.getTime() + 30 * 86400000) },
      },
      orderBy: { dueDate: 'asc' },
      take: 5,
    });

    const billsInfo = unpaidBills.map((b) => ({
      name: b.name,
      amount: toDecimalOrZero(b.amount).toFixed(2),
      dueDate: b.dueDate.toISOString().split('T')[0],
    }));

    const key = `${userId}:low_balance:${now.getFullYear()}-${now.getMonth()}`;
    await alertService.createAlert({
      userId,
      snapshotId: currentSnapshot.id,
      type: 'low_balance',
      severity: projectedBalance.lt(0) ? 'critical' : 'warning',
      title: projectedBalance.lt(0) ? 'Possible negative balance' : 'Low balance warning',
      message: `Your projected month-end balance is ₱${projectedBalance.toFixed(2)}. This is below your ₱${minThreshold.toFixed(2)} threshold.`,
      reasonData: {
        projectedBalance: projectedBalance.toNumber(),
        minThreshold: minThreshold.toNumber(),
        upcomingBills: billsInfo,
      },
      effectiveDate: now,
      deduplicationKey: key,
    });
  } else {
    // Resolve if no longer low
    await alertService.resolveAlertsByKey(userId, `${userId}:low_balance:`);
  }

  // --- Month-end forecast alert ---
  if (projectedBalance.lt(0)) {
    const key = `${userId}:month_end:${now.getFullYear()}-${now.getMonth()}`;
    await alertService.createAlert({
      userId,
      snapshotId: currentSnapshot.id,
      type: 'month_end',
      severity: 'warning',
      title: 'Month-end deficit predicted',
      message: `Your predicted month-end balance is ₱${projectedBalance.toFixed(2)}. Review your spending to avoid a deficit.`,
      reasonData: { predictedMonthEndBalance: projectedBalance.toNumber() },
      effectiveDate: now,
      deduplicationKey: key,
    });
  } else {
    await alertService.resolveAlertsByKey(userId, `${userId}:month_end:`);
  }

  // --- Savings Goal Alerts ---
  // One grouped aggregation for all goals instead of two queries per goal.
  const goals = await prisma.savingsGoal.findMany({
    where: { userId, status: 'active', targetDate: { not: null } },
  });
  await alertService.resolveAlertsByKey(userId, `${userId}:savings_goal:`);

  if (goals.length > 0) {
    const goalIds = goals.map((goal) => goal.id);
    const threeMonthsAgo = new Date(now);
    threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

    const [totalsByGoal, recentByGoal] = await Promise.all([
      prisma.savingsContribution.groupBy({
        by: ['goalId'],
        where: { userId, goalId: { in: goalIds } },
        _sum: { amount: true },
      }),
      prisma.savingsContribution.groupBy({
        by: ['goalId'],
        where: {
          userId,
          goalId: { in: goalIds },
          contributedAt: { gte: threeMonthsAgo, lte: now },
        },
        _sum: { amount: true },
      }),
    ]);
    const totalsMap = new Map(
      totalsByGoal.map((row) => [row.goalId, toDecimalOrZero(row._sum.amount)]),
    );
    const recentMap = new Map(
      recentByGoal.map((row) => [row.goalId, toDecimalOrZero(row._sum.amount)]),
    );

    for (const goal of goals) {
      if (!goal.targetDate) continue;

      const totalContributed = totalsMap.get(goal.id) ?? new Decimal(0);
      const targetAmount = toDecimalOrZero(goal.targetAmount);
      const remaining = targetAmount.minus(totalContributed);

      if (remaining.lte(0)) continue;

      const monthsUntilTarget = daysBetween(now, goal.targetDate) / 30;
      if (monthsUntilTarget <= 0) continue;

      const averageMonthly = (recentMap.get(goal.id) ?? new Decimal(0)).div(3);
      const neededMonthly = remaining.div(monthsUntilTarget);
      if (averageMonthly.lt(neededMonthly)) {
        const key = `${userId}:savings_goal:${goal.id}`;
        const severity = averageMonthly.lte(0) || neededMonthly.div(averageMonthly).gt(2)
          ? 'critical'
          : 'warning';
        await alertService.createAlert({
          userId,
          snapshotId: currentSnapshot.id,
          type: 'savings_goal',
          severity,
          title: 'Savings goal may be delayed',
          message: `Your goal "${goal.name}" needs ₱${neededMonthly.toFixed(2)}/month to stay on track, but you're contributing ₱${averageMonthly.toFixed(2)}/month on average.`,
          reasonData: {
            goalName: goal.name,
            targetAmount: targetAmount.toNumber(),
            totalContributed: totalContributed.toNumber(),
            remaining: remaining.toNumber(),
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
  await alertService.resolveAlertsByKey(userId, `${userId}:bill_due:`);

  for (const bill of upcomingBills) {
    const daysUntilDue = daysBetween(now, bill.dueDate);
    const key = `${userId}:bill_due:${bill.id}`;
    const billAmount = toDecimalOrZero(bill.amount).toFixed(2);

    await alertService.createAlert({
      userId,
      snapshotId: currentSnapshot.id,
      type: 'bill_due',
      severity: daysUntilDue <= 1 ? 'warning' : 'info',
      title: `Bill due ${daysUntilDue === 0 ? 'today' : `in ${daysUntilDue} days`}`,
      message: `"${bill.name}" of ₱${billAmount} is due on ${bill.dueDate.toISOString().split('T')[0]}.`,
      reasonData: {
        billName: bill.name,
        amount: billAmount,
        dueDate: bill.dueDate.toISOString().split('T')[0],
        daysUntilDue,
      },
      effectiveDate: now,
      deduplicationKey: key,
    });
  }

  // --- High Expense Spike / Deficit Alert ---
  const expensesMTD = toDecimalOrZero(currentSnapshot.expensesMonthToDate);
  const incomeMTD = toDecimalOrZero(currentSnapshot.incomeMonthToDate);

  if (expensesMTD.gt(0) && (incomeMTD.lte(0) || expensesMTD.gt(incomeMTD.times(0.8)))) {
    const key = `${userId}:expense_spike:${now.getFullYear()}-${now.getMonth()}`;
    const severity = expensesMTD.gt(incomeMTD) ? 'critical' : 'warning';
    await alertService.createAlert({
      userId,
      snapshotId: currentSnapshot.id,
      type: 'budget_overrun',
      severity,
      title: severity === 'critical' ? 'High expense spike warning' : 'Elevated spending rate',
      message: `Your month-to-date expenses (₱${expensesMTD.toFixed(2)}) reach ${incomeMTD.gt(0) ? expensesMTD.div(incomeMTD).times(100).toFixed(0) : '100'}% of your recorded income (₱${incomeMTD.toFixed(2)}).`,
      reasonData: { expensesMTD: expensesMTD.toNumber(), incomeMTD: incomeMTD.toNumber() },
      effectiveDate: now,
      deduplicationKey: key,
    });
  } else {
    await alertService.resolveAlertsByKey(userId, `${userId}:expense_spike:`);
  }

  // --- Health Score Alert ---
  const healthGrade = currentSnapshot.healthGrade;
  if (healthGrade === 'Needs Attention' || healthGrade === 'Fair') {
    const key = `${userId}:health_score:${now.getFullYear()}-${now.getMonth()}`;
    await alertService.createAlert({
      userId,
      snapshotId: currentSnapshot.id,
      type: 'month_end',
      severity: healthGrade === 'Needs Attention' ? 'critical' : 'warning',
      title: `Financial Health: ${healthGrade}`,
      message: `Your health score needs attention due to high spending relative to income or balance threshold. Check recovery steps below.`,
      reasonData: { healthGrade, healthScore: currentSnapshot.healthScore },
      effectiveDate: now,
      deduplicationKey: key,
    });
  } else {
    await alertService.resolveAlertsByKey(userId, `${userId}:health_score:`);
  }
}

export interface RecoveryPlanOutput {
  healthScore: number;
  healthGrade: string;
  summaryMessage: string;
  rootCauses: {
    title: string;
    description: string;
    severity: 'critical' | 'warning' | 'info';
  }[];
  recommendedDailySpendLimit: number;
  daysRemainingInMonth: number;
  safeLiquidCash: number;
  estimatedRecoveryDate: string | null;
  actionSteps: {
    stepNumber: number;
    title: string;
    description: string;
    icon: string;
  }[];
}

export async function evaluateFinancialRecoveryAnalysis(userId: string): Promise<RecoveryPlanOutput> {
  const now = new Date();
  const snapshot = await computeSnapshot(userId);
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { minimumBalanceThreshold: true, salaryAmount: true, timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';

  const activeBills = await prisma.billInstance.findMany({
    where: {
      userId,
      status: { in: ['upcoming', 'overdue'] },
      dueDate: { lte: new Date(now.getTime() + 30 * 86400000) },
    },
  });

  const totalBills = activeBills.reduce(
    (sum, b) => sum.plus(toDecimalOrZero(b.amount)),
    new Decimal(0),
  );
  const minThreshold = toDecimalOrZero(user?.minimumBalanceThreshold);
  const actualBalance = toDecimalOrZero(snapshot.actualBalance);
  const expensesMTD = toDecimalOrZero(snapshot.expensesMonthToDate);
  const incomeMTD = toDecimalOrZero(snapshot.incomeMonthToDate);
  const projectedMonthEnd = toDecimalOrZero(snapshot.predictedMonthEndBalance);

  const parts = getZonedParts(now, timeZone);
  const daysInMonthTotal = new Date(parts.year, parts.month, 0).getDate();
  const daysRemaining = Math.max(1, daysInMonthTotal - parts.day);

  const safeLiquidCash = actualBalance.minus(totalBills).minus(minThreshold);
  const rawDailyLimit = safeLiquidCash.gt(0)
    ? safeLiquidCash.div(daysRemaining)
    : new Decimal(0);
  const recommendedDailySpendLimit = Decimal.max(0, rawDailyLimit.floor()).toNumber();

  const rootCauses: { title: string; description: string; severity: 'critical' | 'warning' | 'info' }[] = [];

  if (expensesMTD.gt(incomeMTD) && incomeMTD.gt(0)) {
    rootCauses.push({
      title: 'Expense Spike Exceeds Income',
      description: `Your MTD expenses (₱${expensesMTD.toFixed(2)}) have exceeded your MTD income (₱${incomeMTD.toFixed(2)}).`,
      severity: 'critical',
    });
  } else if (expensesMTD.gt(0) && incomeMTD.lte(0)) {
    rootCauses.push({
      title: 'Expenses Recorded Without Salary/Income',
      description: `Recorded ₱${expensesMTD.toFixed(2)} in expenses without a salary or income baseline configured.`,
      severity: 'warning',
    });
  }

  if (projectedMonthEnd.lt(minThreshold)) {
    rootCauses.push({
      title: 'Projected Month-End Below Safety Buffer',
      description: `Projected month-end balance (₱${projectedMonthEnd.toFixed(2)}) falls below your ₱${minThreshold.toFixed(2)} safety buffer.`,
      severity: projectedMonthEnd.lt(0) ? 'critical' : 'warning',
    });
  }

  if (totalBills.gt(0) && actualBalance.lt(totalBills)) {
    rootCauses.push({
      title: 'Upcoming Bills Exceed Current Liquid Balance',
      description: `Upcoming 30-day bills total ₱${totalBills.toFixed(2)}, which exceeds liquid balance (₱${actualBalance.toFixed(2)}).`,
      severity: 'critical',
    });
  }

  if (rootCauses.length === 0) {
    rootCauses.push({
      title: 'Normal Operations',
      description: 'Your cash flow velocity and balance safety buffer are currently in healthy shape.',
      severity: 'info',
    });
  }

  let estimatedRecoveryDate: string | null = null;
  const observedMonthlyCashflow = toDecimalOrZero(snapshot.incomeMonthToDate).minus(
    toDecimalOrZero(snapshot.expensesMonthToDate),
  );
  const dailySurplus = observedMonthlyCashflow.gt(0)
    ? observedMonthlyCashflow.div(30)
    : new Decimal(0);

  if (safeLiquidCash.lt(0) && dailySurplus.gt(0)) {
    const deficit = safeLiquidCash.abs();
    const daysNeeded = Math.ceil(deficit.div(dailySurplus).toNumber());
    const recoverDate = new Date(now.getTime() + daysNeeded * 86400000);
    estimatedRecoveryDate = recoverDate.toISOString().split('T')[0];
  }

  const actionSteps = [
    {
      stepNumber: 1,
      title: `Cap Daily Variable Spend at ₱${recommendedDailySpendLimit.toFixed(0)}/day`,
      description: `For the remaining ${daysRemaining} days of this month, limit discretionary spending to ₱${recommendedDailySpendLimit.toFixed(0)} per day to protect your bill buffer.`,
      icon: 'savings',
    },
    {
      stepNumber: 2,
      title: `Secure ₱${totalBills.toFixed(0)} Bill Reserve`,
      description: `Keep at least ₱${totalBills.toFixed(0)} untouchable in your main account to cover 30-day upcoming bill payments without penalties.`,
      icon: 'receipt',
    },
    {
      stepNumber: 3,
      title: 'Pause Non-Essential Purchases',
      description: 'Avoid large gadget, dining, or luxury expenses until your health score rebounds above 70 (Good).',
      icon: 'pause_circle',
    },
  ];

  let summaryMessage = 'Your overall finances look healthy and on track.';
  if (snapshot.healthGrade === 'Needs Attention') {
    summaryMessage = `Attention required: Recent expenses have created a cash flow deficit. Follow the recovery plan below to reach balance stability.`;
  } else if (snapshot.healthGrade === 'Fair') {
    summaryMessage = `Caution: Your cash flow buffer is tight. Pacing your daily spending will maintain healthy balance resilience.`;
  }

  return {
    healthScore: snapshot.healthScore,
    healthGrade: snapshot.healthGrade,
    summaryMessage,
    rootCauses,
    recommendedDailySpendLimit,
    daysRemainingInMonth: daysRemaining,
    safeLiquidCash: safeLiquidCash.toNumber(),
    estimatedRecoveryDate,
    actionSteps,
  };
}

export interface HealthInput {
  incomeMTD: Decimal;
  expensesMTD: Decimal;
  savingsMTD: Decimal;
  projectedMonthEndExpenses: Decimal;
  projectedMonthEndIncome?: Decimal;
  actualBalance: Decimal;
  predictedMonthEndBalance: Decimal;
  userId?: string;
  now?: Date;
  billPaymentRate: number; // -1 means no billing history
}

export interface HealthOutput {
  score: number;
  grade: HealthGrade;
}

export function computeHealthScore(input: HealthInput): HealthOutput {
  const { incomeMTD, savingsMTD } = input;

  // --- Savings score (30%) ---
  const savingsRate = incomeMTD.gt(0) ? Number(savingsMTD.div(incomeMTD)) : 0;
  const savingsScore = (() => {
    if (savingsRate >= 0.20) return 100;
    if (savingsRate >= 0.10) return 70 + (savingsRate - 0.10) / 0.10 * 29;
    if (savingsRate > 0) return 30 + (savingsRate / 0.10) * 39;
    return 0;
  })();

  // --- Budget score (30%) ---
  // Compares full-month projected expenses against full-month projected income
  // (falling back to incomeMTD if projected income is absent or non-positive).
  const budgetTotal = input.projectedMonthEndExpenses.toNumber();
  const effectiveIncome = (input.projectedMonthEndIncome && input.projectedMonthEndIncome.gt(0))
    ? input.projectedMonthEndIncome.toNumber()
    : incomeMTD.toNumber();
  const budgetRatio = effectiveIncome > 0 ? budgetTotal / effectiveIncome : 1;

  const budgetScore = (() => {
    if (budgetRatio <= 0.90) return 100;
    if (budgetRatio <= 1.00) return 70 + (1 - budgetRatio) / 0.10 * 29;
    if (budgetRatio <= 1.15) return 30 + (1.15 - budgetRatio) / 0.15 * 39;
    return Math.max(0, 30 - (budgetRatio - 1.15) / 0.15 * 30);
  })();
  // --- Bill reliability score (20%) ---
  const rate = input.billPaymentRate;
  let billScore: number;
  if (rate === -1) {
    billScore = 85; // No bill history
  } else if (rate >= 0.95) {
    billScore = 100;
  } else if (rate >= 0.80) {
    billScore = 70 + (rate - 0.80) / 0.15 * 29;
  } else if (rate >= 0.50) {
    billScore = 30 + (rate - 0.50) / 0.30 * 39;
  } else {
    billScore = Math.max(0, rate / 0.50 * 30);
  }
  // --- Balance resilience score (20%) ---
  const resilienceIncome = effectiveIncome;
  const projectedBalance = input.predictedMonthEndBalance.toNumber();
  const resilienceScore = projectedBalance > 0
    ? Math.min(100, 50 + (projectedBalance / (resilienceIncome || 1)) * 100)
    : Math.max(0, 50 + (projectedBalance / (resilienceIncome || 1)) * 50);

  // --- Composite ---
  const totalScore = Math.round(
    savingsScore * 0.30 + budgetScore * 0.30 + billScore * 0.20 + resilienceScore * 0.20
  );

  let grade: HealthGrade;
  if (totalScore >= 85) grade = 'Excellent';
  else if (totalScore >= 70) grade = 'Good';
  else if (totalScore >= 50) grade = 'Fair';
  else grade = 'Needs Attention';

  return { score: totalScore, grade };
}
