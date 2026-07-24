import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import { startOfMonth, endOfMonth, daysBetween } from '../../lib/dates';
import type { CreateGoalInput, UpdateGoalInput, CreateContributionInput } from './validation';

export async function listGoals(userId: string) {
  return prisma.savingsGoal.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
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
  const remaining = targetAmount - totalContributed;

  // Calculate average monthly contribution (last 3 months)
  const threeMonthsAgo = new Date();
  threeMonthsAgo.setMonth(threeMonthsAgo.getMonth() - 3);

  const recentAgg = await prisma.savingsContribution.aggregate({
    where: {
      goalId,
      contributedAt: { gte: threeMonthsAgo },
    },
    _sum: { amount: true },
  });

  const recentTotal = Number(recentAgg._sum.amount) || 0;
  const avgMonthlyContribution = recentTotal / 3;

  let forecastCompletion: string | null = null;
  let isOnTrack: boolean | null = null;

  if (avgMonthlyContribution > 0 && remaining > 0) {
    const monthsRemaining = remaining / avgMonthlyContribution;
    const forecastDate = new Date();
    forecastDate.setMonth(forecastDate.getMonth() + Math.ceil(monthsRemaining));
    forecastCompletion = forecastDate.toISOString().split('T')[0];

    if (goal.targetDate) {
      const monthsUntilTarget = daysBetween(new Date(), goal.targetDate) / 30;
      isOnTrack = monthsRemaining <= monthsUntilTarget;
    }
  }

  return {
    goalId: goal.id,
    name: goal.name,
    targetAmount: targetAmount.toFixed(2),
    totalContributed: totalContributed.toFixed(2),
    percentageComplete: Math.round(percentageComplete * 10) / 10,
    remaining: remaining.toFixed(2),
    contributionCount: agg._count.id,
    avgMonthlyContribution: avgMonthlyContribution.toFixed(2),
    forecastCompletion,
    isOnTrack,
    status: goal.status,
  };
}
