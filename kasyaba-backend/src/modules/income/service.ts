import { prisma } from '../../config/database';
import { ConflictError, NotFoundError } from '../../lib/errors';
import { Prisma } from '@prisma/client';
import { parseDateOnlyEnd, parseDateOnlyStart, parseTransactionDate } from '../../lib/transaction-dates';
import { inferTransactionStatus } from '../../lib/transaction-status';
import type { CreateIncomeInput, UpdateIncomeInput } from './validation';

function incomeSelect() {
  return {
    id: true,
    userId: true,
    accountId: true,
    amount: true,
    source: true,
    receivedAt: true,
    status: true,
    notes: true,
    clientMutationId: true,
    createdAt: true,
    updatedAt: true,
  };
}

async function assertAccountOwned(userId: string, accountId: string, activeOnly = false) {
  const account = await prisma.financialAccount.findFirst({
    where: { id: accountId, userId, ...(activeOnly ? { isArchived: false } : {}) },
    select: { id: true },
  });
  if (!account) throw new NotFoundError('Account not found');
}

export async function listIncome(userId: string, query: Record<string, any>) {
  const where: any = { userId };

  if (query.from || query.to) {
    where.receivedAt = {};
    if (query.from) where.receivedAt.gte = parseDateOnlyStart(query.from);
    if (query.to) where.receivedAt.lte = parseDateOnlyEnd(query.to);
  }
  if (query.source) where.source = { contains: query.source, mode: 'insensitive' };
  if (query.accountId) where.accountId = query.accountId;

  const page = query.page || 1;
  const limit = query.limit || 20;
  const skip = (page - 1) * limit;

  const [data, total] = await Promise.all([
    prisma.incomeEntry.findMany({
      where,
      select: incomeSelect(),
      orderBy: { receivedAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.incomeEntry.count({ where }),
  ]);

  return { data, meta: { page, limit, total } };
}

export async function getIncome(userId: string, id: string) {
  const entry = await prisma.incomeEntry.findFirst({
    where: { id, userId },
    select: incomeSelect(),
  });
  if (!entry) throw new NotFoundError('Income entry not found');
  return entry;
}

export async function createIncome(userId: string, input: CreateIncomeInput) {
  if (input.clientMutationId) {
    const existing = await prisma.incomeEntry.findUnique({
      where: { clientMutationId: input.clientMutationId },
      select: incomeSelect(),
    });
    if (existing) {
      if (existing.userId !== userId) throw new ConflictError('Client mutation ID already used');
      return existing;
    }
  }

  await assertAccountOwned(userId, input.accountId, true);
  const receivedAt = parseTransactionDate(input.receivedAt);

  try {
    return await prisma.incomeEntry.create({
      data: {
        userId,
        accountId: input.accountId,
        amount: input.amount,
        source: input.source,
        receivedAt,
        status: inferTransactionStatus(receivedAt, input.status),
        notes: input.notes,
        clientMutationId: input.clientMutationId,
      },
      select: incomeSelect(),
    });
  } catch (error) {
    if (
      input.clientMutationId &&
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      const existing = await prisma.incomeEntry.findUnique({
        where: { clientMutationId: input.clientMutationId },
        select: incomeSelect(),
      });
      if (existing?.userId === userId) return existing;
      throw new ConflictError('Client mutation ID already used');
    }
    throw error;
  }
}

export async function updateIncome(userId: string, id: string, input: UpdateIncomeInput) {
  await getIncome(userId, id);
  if (input.accountId) await assertAccountOwned(userId, input.accountId, true);
  const data: any = { ...input };
  if (input.receivedAt) {
    data.receivedAt = parseTransactionDate(input.receivedAt);
    if (!input.status) data.status = inferTransactionStatus(data.receivedAt, undefined);
  }
  return prisma.incomeEntry.update({
    where: { id },
    data,
    select: incomeSelect(),
  });
}

export async function deleteIncome(userId: string, id: string) {
  await getIncome(userId, id);
  await prisma.incomeEntry.delete({ where: { id } });
}
