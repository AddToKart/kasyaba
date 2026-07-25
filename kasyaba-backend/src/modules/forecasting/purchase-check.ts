import Decimal from 'decimal.js';
import { prisma } from '../../config/database';
import { computeSnapshot } from './service';

export interface PurchaseCheckInput {
  itemTitle: string;
  amount: number;
}

export interface PurchaseCheckResult {
  itemTitle: string;
  amount: number;
  verdict: 'AFFORDABLE' | 'RISKY' | 'NOT_RECOMMENDED';
  statusTitle: string;
  statusMessage: string;
  currentBalance: number;
  postPurchaseBalance: number;
  projectedMonthEndBalance: number;
  postPurchaseMonthEndBalance: number;
  totalUpcomingBills: number;
  cashAfterBills: number;
  minimumThreshold: number;
  earliestSafeBuyDate: string | null;
  daysUntilSafeBuy: number | null;
  dailySurplus: number;
  reasons: string[];
  goalImpacts: {
    goalName: string;
    originalTargetDate: string | null;
    delayedTargetDate: string | null;
    delayDays: number;
  }[];
}

export async function evaluatePurchaseAffordability(
  userId: string,
  input: PurchaseCheckInput
): Promise<PurchaseCheckResult> {
  const purchaseAmount = new Decimal(input.amount);
  const now = new Date();

  // 1. Baseline forecast snapshot & user settings
  const [snapshot, user, activeBills, activeGoals] = await Promise.all([
    computeSnapshot(userId),
    prisma.user.findUnique({
      where: { id: userId },
      select: { minimumBalanceThreshold: true, salaryAmount: true },
    }),
    prisma.billInstance.findMany({
      where: {
        userId,
        status: 'upcoming',
        dueDate: { gte: now, lte: new Date(now.getTime() + 30 * 86400000) },
      },
      select: { amount: true },
    }),
    prisma.savingsGoal.findMany({
      where: { userId, status: 'active' },
      include: { contributions: { select: { amount: true } } },
    }),
  ]);

  const currentBalance = new Decimal(snapshot.actualBalance);
  const projectedMonthEnd = new Decimal(snapshot.predictedMonthEndBalance);
  const minThreshold = new Decimal(user?.minimumBalanceThreshold ? Number(user.minimumBalanceThreshold) : 0);

  // 2. Upcoming bills total
  const totalUpcomingBills = activeBills.reduce(
    (sum, b) => sum.plus(new Decimal(Number(b.amount))),
    new Decimal(0)
  );

  // 3. Post-purchase simulations
  const postPurchaseBalance = currentBalance.minus(purchaseAmount);
  const postPurchaseMonthEnd = projectedMonthEnd.minus(purchaseAmount);
  const cashAfterBills = postPurchaseBalance.minus(totalUpcomingBills);

  // 4. Daily net surplus calculation
  const userSalary = user?.salaryAmount ? new Decimal(Number(user.salaryAmount)) : new Decimal(0);
  const mtdExpenses = new Decimal(snapshot.expensesMonthToDate);
  const monthlyCashflow = userSalary.gt(0) ? userSalary.minus(mtdExpenses) : currentBalance;
  const rawSurplus = monthlyCashflow.gt(0) ? monthlyCashflow.div(30) : new Decimal(150);
  const dailySurplus = Decimal.max(new Decimal(50), rawSurplus);

  // 5. Verdict Matrix Logic
  let verdict: 'AFFORDABLE' | 'RISKY' | 'NOT_RECOMMENDED';
  let statusTitle: string;
  let statusMessage: string;

  const reasons: string[] = [];

  const isNegative = postPurchaseBalance.lt(0);
  const cannotCoverBills = cashAfterBills.lt(minThreshold);
  const belowThreshold = postPurchaseBalance.lt(minThreshold) || postPurchaseMonthEnd.lt(minThreshold);

  if (isNegative) {
    verdict = 'NOT_RECOMMENDED';
    statusTitle = '❌ Insufficient Funds';
    statusMessage = 'This purchase would turn your balance negative immediately.';
    reasons.push(`Immediate balance deficit of ₱${postPurchaseBalance.abs().toFixed(2)}.`);
  } else if (cannotCoverBills) {
    verdict = 'NOT_RECOMMENDED';
    statusTitle = '❌ Unable to Cover Upcoming Bills';
    statusMessage = 'Buying this will leave you short for your upcoming bills over the next 30 days.';
    reasons.push(
      `Required for upcoming bills: ₱${totalUpcomingBills.toFixed(2)}. Remaining liquid cash would be only ₱${postPurchaseBalance.toFixed(2)}.`
    );
  } else if (belowThreshold) {
    verdict = 'RISKY';
    statusTitle = '⚠️ High Risk Purchase';
    statusMessage = 'You can technically buy this, but it will drop your balance below your safety threshold.';
    reasons.push(
      `Your balance drops to ₱${postPurchaseBalance.toFixed(2)}, below your ₱${minThreshold.toFixed(2)} safety threshold.`
    );
  } else {
    verdict = 'AFFORDABLE';
    statusTitle = '✅ Safely Affordable';
    statusMessage = 'You can safely afford this purchase without compromising your bills or safety buffer!';
    reasons.push(
      `You will retain ₱${cashAfterBills.toFixed(2)} in free cash flow after all upcoming bills are covered.`
    );
  }

  reasons.push(
    `Projected month-end balance adjusts from ₱${projectedMonthEnd.toFixed(2)} to ₱${postPurchaseMonthEnd.toFixed(2)}.`
  );

  // 6. Earliest Safe Buy Date ($T_{safe}$)
  let earliestSafeBuyDate: string | null = null;
  let daysUntilSafeBuy: number | null = null;

  if (verdict !== 'AFFORDABLE') {
    const targetRequiredCash = purchaseAmount.plus(totalUpcomingBills).plus(minThreshold);
    const deficit = targetRequiredCash.minus(currentBalance);
    if (deficit.gt(0)) {
      daysUntilSafeBuy = Math.ceil(deficit.div(dailySurplus).toNumber());
      const safeDate = new Date(now.getTime() + daysUntilSafeBuy * 86400000);
      earliestSafeBuyDate = safeDate.toISOString().split('T')[0];
      reasons.push(
        `At your net daily saving rate of ₱${dailySurplus.toFixed(2)}/day, you can safely buy this on ${earliestSafeBuyDate} (${daysUntilSafeBuy} days).`
      );
    }
  }

  // 7. Goal Delay Impact ($\Delta T_{goal}$)
  const delayDays = Math.ceil(purchaseAmount.div(dailySurplus).toNumber());
  const goalImpacts = activeGoals.map((g) => {
    const origDate = g.targetDate ? g.targetDate.toISOString().split('T')[0] : null;
    let delayedTargetDate: string | null = null;
    if (g.targetDate) {
      const d = new Date(g.targetDate.getTime() + delayDays * 86400000);
      delayedTargetDate = d.toISOString().split('T')[0];
    }
    return {
      goalName: g.name,
      originalTargetDate: origDate,
      delayedTargetDate,
      delayDays,
    };
  });

  if (goalImpacts.length > 0 && delayDays > 0) {
    reasons.push(`Note: Making this purchase will delay active savings goals by ~${delayDays} days.`);
  }

  return {
    itemTitle: input.itemTitle,
    amount: purchaseAmount.toNumber(),
    verdict,
    statusTitle,
    statusMessage,
    currentBalance: currentBalance.toNumber(),
    postPurchaseBalance: postPurchaseBalance.toNumber(),
    projectedMonthEndBalance: projectedMonthEnd.toNumber(),
    postPurchaseMonthEndBalance: postPurchaseMonthEnd.toNumber(),
    totalUpcomingBills: totalUpcomingBills.toNumber(),
    cashAfterBills: cashAfterBills.toNumber(),
    minimumThreshold: minThreshold.toNumber(),
    earliestSafeBuyDate,
    daysUntilSafeBuy,
    dailySurplus: dailySurplus.toNumber(),
    reasons,
    goalImpacts,
  };
}
