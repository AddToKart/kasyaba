import Decimal from 'decimal.js';
import { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { toDecimalOrZero } from '../../lib/decimal';
import { NotFoundError } from '../../lib/errors';
import type { CreateGoalInput, UpdateGoalInput, CreateContributionInput } from './validation';

async function getUserDailySurplus(userId: string): Promise<Decimal> {
  const now = new Date();
  const thirtyDaysAgo = new Date(now.getTime() - 30 * 86400000);

  const [incomeAgg, expenseAgg] = await Promise.all([
    prisma.incomeEntry.aggregate({
      where: { userId, status: { in: ['posted', 'planned'] }, receivedAt: { gte: thirtyDaysAgo, lte: now } },
      _sum: { amount: true },
    }),
    prisma.expenseEntry.aggregate({
      where: { userId, status: { in: ['posted', 'planned'] }, spentAt: { gte: thirtyDaysAgo, lte: now } },
      _sum: { amount: true },
    }),
  ]);

  const net30 = toDecimalOrZero(incomeAgg._sum.amount).minus(
    toDecimalOrZero(expenseAgg._sum.amount),
  );
  return net30.gt(0) ? net30.div(30) : new Decimal(0);
}

export async function listGoals(userId: string) {
  const [goals, dailySurplus] = await Promise.all([
    prisma.savingsGoal.findMany({
      where: { userId },
      include: {
        contributions: {
          where: { userId },
          select: { amount: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    }),
    getUserDailySurplus(userId),
  ]);

  const now = new Date();

  return goals.map((goal) => {
    const currentAmount = goal.contributions.reduce(
      (sum, c) => sum.plus(toDecimalOrZero(c.amount)),
      new Decimal(0),
    );
    const targetAmount = toDecimalOrZero(goal.targetAmount);
    const remaining = Decimal.max(0, targetAmount.minus(currentAmount));

    let canAffordByTargetDate: boolean | null = null;
    let earliestAffordableDate: string | null = null;
    let monthlySavingsRequired: number | null = null;
    let daysRemaining: number | null = null;

    if (remaining.lte(0)) {
      canAffordByTargetDate = true;
      earliestAffordableDate = now.toISOString().split('T')[0];
      monthlySavingsRequired = 0;
    } else {
      if (dailySurplus.gt(0)) {
        const daysToSave = Math.ceil(remaining.div(dailySurplus).toNumber());
        const estDate = new Date(now.getTime() + daysToSave * 86400000);
        earliestAffordableDate = estDate.toISOString().split('T')[0];
      }

      if (goal.targetDate) {
        const targetTime = new Date(goal.targetDate).getTime();
        daysRemaining = Math.max(1, Math.ceil((targetTime - now.getTime()) / 86400000));
        const projectedSavings = currentAmount.plus(dailySurplus.times(daysRemaining));
        canAffordByTargetDate = projectedSavings.gte(targetAmount);
        monthlySavingsRequired = remaining
          .div(daysRemaining)
          .times(30)
          .toDecimalPlaces(2)
          .toNumber();
      }
    }

    return {
      id: goal.id,
      name: goal.name,
      targetAmount: targetAmount.toNumber(),
      currentAmount: currentAmount.toNumber(),
      targetDate: goal.targetDate ? goal.targetDate.toISOString().split('T')[0] : null,
      status: goal.status,
      createdAt: goal.createdAt.toISOString(),
      updatedAt: goal.updatedAt.toISOString(),
      canAffordByTargetDate,
      earliestAffordableDate,
      monthlySavingsRequired,
      daysRemaining,
      dailySurplus: dailySurplus.toDecimalPlaces(2).toNumber(),
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

  // Idempotent replay: an offline-queued contribution that was already stored
  // returns the original row instead of double-counting the amount.
  if (input.clientMutationId) {
    const existing = await prisma.savingsContribution.findUnique({
      where: { clientMutationId: input.clientMutationId },
    });
    if (existing) return existing;
  }

  if (input.accountId) {
    const account = await prisma.financialAccount.findFirst({
      where: { id: input.accountId, userId, isArchived: false },
      select: { id: true },
    });
    if (!account) throw new NotFoundError('Account not found');
  }

  try {
    return await prisma.savingsContribution.create({
      data: {
        goalId,
        userId,
        accountId: input.accountId || null,
        amount: input.amount,
        contributedAt: input.contributedAt ? new Date(input.contributedAt) : new Date(),
        notes: input.notes,
        clientMutationId: input.clientMutationId ?? null,
      },
    });
  } catch (err) {
    // Two concurrent retries of the same queued contribution can race between
    // the lookup and the insert; the unique index guarantees one winner.
    if (
      err instanceof Prisma.PrismaClientKnownRequestError &&
      err.code === 'P2002' &&
      input.clientMutationId
    ) {
      const existing = await prisma.savingsContribution.findUnique({
        where: { clientMutationId: input.clientMutationId },
      });
      if (existing) return existing;
    }
    throw err;
  }
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
    where: { goalId, userId },
    _sum: { amount: true },
    _count: { id: true },
  });

  const totalContributed = toDecimalOrZero(agg._sum.amount);
  const targetAmount = toDecimalOrZero(goal.targetAmount);
  const percentageComplete = targetAmount.gt(0)
    ? totalContributed.div(targetAmount).times(1000).round().div(10).toNumber()
    : 0;
  const remaining = Decimal.max(0, targetAmount.minus(totalContributed));

  const dailySurplus = await getUserDailySurplus(userId);
  const now = new Date();
  const earliestAffordableDate = dailySurplus.gt(0)
    ? new Date(
        now.getTime() +
          Math.ceil(remaining.div(dailySurplus).toNumber()) * 86400000,
      ).toISOString().split('T')[0]
    : null;

  let canAffordByTargetDate: boolean | null = null;
  let monthlySavingsRequired: number | null = null;

  if (goal.targetDate) {
    const daysUntilTarget = Math.max(
      1,
      Math.ceil((new Date(goal.targetDate).getTime() - now.getTime()) / 86400000),
    );
    const projectedSavings = totalContributed.plus(dailySurplus.times(daysUntilTarget));
    canAffordByTargetDate = projectedSavings.gte(targetAmount);
    monthlySavingsRequired = remaining
      .div(daysUntilTarget)
      .times(30)
      .toDecimalPlaces(2)
      .toNumber();
  }

  return {
    goalId: goal.id,
    name: goal.name,
    targetAmount: targetAmount.toFixed(2),
    totalContributed: totalContributed.toFixed(2),
    percentageComplete,
    remaining: remaining.toFixed(2),
    contributionCount: agg._count.id,
    canAffordByTargetDate,
    earliestAffordableDate,
    monthlySavingsRequired,
    dailySurplus: dailySurplus.toDecimalPlaces(2).toNumber(),
    status: goal.status,
  };
}
