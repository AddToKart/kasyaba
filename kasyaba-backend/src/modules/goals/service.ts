import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import { daysBetween } from '../../lib/dates';
import type { CreateGoalInput, UpdateGoalInput, CreateContributionInput } from './validation';

async function getUserDailySurplus(userId: string): Promise<number> {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000);

  const [incomeAgg, expenseAgg] = await Promise.all([
    prisma.incomeEntry.aggregate({
      where: { userId, receivedAt: { gte: thirtyDaysAgo } },
      _sum: { amount: true },
    }),
    prisma.expenseEntry.aggregate({
      where: { userId, spentAt: { gte: thirtyDaysAgo } },
      _sum: { amount: true },
    }),
  ]);

  const totalIncome = Number(incomeAgg._sum.amount) || 0;
  const totalExpenses = Number(expenseAgg._sum.amount) || 0;
  const net30 = totalIncome - totalExpenses;
  const dailySurplus = net30 > 0 ? net30 / 30 : 150;
  return Math.max(50, dailySurplus);
}

export async function listGoals(userId: string) {
  const [goals, dailySurplus] = await Promise.all([
    prisma.savingsGoal.findMany({
      where: { userId },
      include: {
        contributions: {
          select: { amount: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    }),
    getUserDailySurplus(userId),
  ]);

  const now = new Date();

  return goals.map((goal) => {
    const currentAmount = goal.contributions.reduce((s, c) => s + Number(c.amount), 0);
    const targetAmount = Number(goal.targetAmount);
    const remaining = Math.max(0, targetAmount - currentAmount);

    let canAffordByTargetDate: boolean | null = null;
    let earliestAffordableDate: string | null = null;
    let monthlySavingsRequired: number | null = null;
    let daysRemaining: number | null = null;

    if (remaining <= 0) {
      canAffordByTargetDate = true;
      earliestAffordableDate = now.toISOString().split('T')[0];
      monthlySavingsRequired = 0;
    } else {
      const daysToSave = Math.ceil(remaining / dailySurplus);
      const estDate = new Date(now.getTime() + daysToSave * 86400000);
      earliestAffordableDate = estDate.toISOString().split('T')[0];

      if (goal.targetDate) {
        const targetTime = new Date(goal.targetDate).getTime();
        daysRemaining = Math.max(1, Math.ceil((targetTime - now.getTime()) / 86400000));
        const projectedSavings = currentAmount + (dailySurplus * daysRemaining);
        canAffordByTargetDate = projectedSavings >= targetAmount;
        monthlySavingsRequired = Math.round((remaining / (daysRemaining / 30)) * 100) / 100;
      }
    }

    return {
      id: goal.id,
      name: goal.name,
      targetAmount,
      currentAmount,
      targetDate: goal.targetDate ? goal.targetDate.toISOString().split('T')[0] : null,
      status: goal.status,
      createdAt: goal.createdAt.toISOString(),
      updatedAt: goal.updatedAt.toISOString(),
      canAffordByTargetDate,
      earliestAffordableDate,
      monthlySavingsRequired,
      daysRemaining,
      dailySurplus: Math.round(dailySurplus * 100) / 100,
    };
  });
}

export async function getGoal(userId: string, id: string) {
  const goal = await prisma.savingsGoal.findFirst({ where: { id, userId } });
  if (!goal) throw new NotFoundError('Savings goal not found');
  return goal;
}

export async function createGoal(userId: string, input: CreateGoalInput) {
  return prisma.savingsGoal.create({
    data: {
      userId,
      name: input.name,
      targetAmount: input.targetAmount,
      targetDate: input.targetDate ? new Date(input.targetDate) : null,
    },
  });
}

export async function updateGoal(userId: string, id: string, input: UpdateGoalInput) {
  await getGoal(userId, id);
  const data: any = { ...input };
  if (input.targetDate !== undefined) data.targetDate = input.targetDate ? new Date(input.targetDate) : null;
  return prisma.savingsGoal.update({ where: { id }, data });
}

export async function addContribution(userId: string, goalId: string, input: CreateContributionInput) {
  await getGoal(userId, goalId);
  return prisma.savingsContribution.create({
    data: {
      goalId,
      userId,
      accountId: input.accountId || null,
      amount: input.amount,
      contributedAt: new Date(input.contributedAt),
      notes: input.notes,
    },
  });
}

export async function deleteContribution(userId: string, goalId: string, contributionId: string) {
  await getGoal(userId, goalId);
  const contrib = await prisma.savingsContribution.findFirst({
    where: { id: contributionId, goalId, userId },
  });
  if (!contrib) throw new NotFoundError('Contribution not found');
  await prisma.savingsContribution.delete({ where: { id: contributionId } });
}

export async function getProgress(userId: string, goalId: string) {
  const goal = await getGoal(userId, goalId);

  const agg = await prisma.savingsContribution.aggregate({
    where: { goalId },
    _sum: { amount: true },
    _count: { id: true },
  });

  const totalContributed = Number(agg._sum.amount) || 0;
  const targetAmount = Number(goal.targetAmount);
  const percentageComplete = targetAmount > 0 ? (totalContributed / targetAmount) * 100 : 0;
  const remaining = Math.max(0, targetAmount - totalContributed);

  const dailySurplus = await getUserDailySurplus(userId);
  const now = new Date();
  const daysToSave = Math.ceil(remaining / dailySurplus);
  const estDate = new Date(now.getTime() + daysToSave * 86400000);
  const earliestAffordableDate = estDate.toISOString().split('T')[0];

  let canAffordByTargetDate: boolean | null = null;
  let monthlySavingsRequired: number | null = null;

  if (goal.targetDate) {
    const daysUntilTarget = Math.max(1, Math.ceil((new Date(goal.targetDate).getTime() - now.getTime()) / 86400000));
    const projectedSavings = totalContributed + (dailySurplus * daysUntilTarget);
    canAffordByTargetDate = projectedSavings >= targetAmount;
    monthlySavingsRequired = Math.round((remaining / (daysUntilTarget / 30)) * 100) / 100;
  }

  return {
    goalId: goal.id,
    name: goal.name,
    targetAmount: targetAmount.toFixed(2),
    totalContributed: totalContributed.toFixed(2),
    percentageComplete: Math.round(percentageComplete * 10) / 10,
    remaining: remaining.toFixed(2),
    contributionCount: agg._count.id,
    canAffordByTargetDate,
    earliestAffordableDate,
    monthlySavingsRequired,
    dailySurplus: Math.round(dailySurplus * 100) / 100,
    status: goal.status,
  };
}
