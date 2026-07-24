import { prisma } from '../../config/database';
import { NotFoundError, ForbiddenError } from '../../lib/errors';
import type { CreateIncomeInput, UpdateIncomeInput } from './validation';

function incomeSelect() {
  return {
    id: true,
    userId: true,
    accountId: true,
    amount: true,
    source: true,
    receivedAt: true,
    notes: true,
    clientMutationId: true,
    createdAt: true,
    updatedAt: true,
  };
}

export async function listIncome(userId: string, query: Record<string, any>) {
  const where: any = { userId };

  if (query.from || query.to) {
    where.receivedAt = {};
    if (query.from) where.receivedAt.gte = new Date(query.from);
    if (query.to) where.receivedAt.lte = new Date(query.to + 'T23:59:59.999Z');
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
  return prisma.incomeEntry.create({
    data: {
      userId,
      accountId: input.accountId,
      amount: input.amount,
      source: input.source,
      receivedAt: new Date(input.receivedAt),
      notes: input.notes,
      clientMutationId: input.clientMutationId,
    },
    select: incomeSelect(),
  });
}

export async function updateIncome(userId: string, id: string, input: UpdateIncomeInput) {
  await getIncome(userId, id);
  const data: any = { ...input };
  if (input.receivedAt) data.receivedAt = new Date(input.receivedAt);
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
