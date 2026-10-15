import { prisma } from '../../config/database';
import { ConflictError, NotFoundError } from '../../lib/errors';
import { toDecimalOrZero } from '../../lib/decimal';
import { Prisma } from '@prisma/client';
import { parseDateOnlyEnd, parseDateOnlyStart, parseTransactionDate } from '../../lib/transaction-dates';
import { inferTransactionStatus } from '../../lib/transaction-status';
import type { CreateExpenseInput, UpdateExpenseInput } from './validation';

function expenseSelect() {
  return {
    id: true,
    userId: true,
    accountId: true,
    categoryId: true,
    amount: true,
    description: true,
    spentAt: true,
    status: true,
    notes: true,
    clientMutationId: true,
    createdAt: true,
    updatedAt: true,
    category: { select: { name: true, iconKey: true } },
  };
}

async function assertAccountOwned(userId: string, accountId: string, activeOnly = false) {
  const account = await prisma.financialAccount.findFirst({
    where: { id: accountId, userId, ...(activeOnly ? { isArchived: false } : {}) },
    select: { id: true },
  });
  if (!account) throw new NotFoundError('Account not found');
}

async function assertCategoryOwned(userId: string, categoryId: string) {
  const category = await prisma.expenseCategory.findFirst({
    where: {
      id: categoryId,
      isArchived: false,
      OR: [{ userId }, { userId: null }],
    },
    select: { id: true },
  });
  if (!category) throw new NotFoundError('Category not found');
}

export async function listExpenses(userId: string, query: Record<string, any>) {
  const where: any = { userId };

  if (query.from || query.to) {
    where.spentAt = {};
    if (query.from) where.spentAt.gte = parseDateOnlyStart(query.from);
    if (query.to) where.spentAt.lte = parseDateOnlyEnd(query.to);
  }
  if (query.categoryId) where.categoryId = query.categoryId;
  if (query.accountId) where.accountId = query.accountId;
  if (query.search) {
    where.description = { contains: query.search, mode: 'insensitive' };
  }

  const page = query.page || 1;
  const limit = query.limit || 20;
  const skip = (page - 1) * limit;

  const [data, total] = await Promise.all([
    prisma.expenseEntry.findMany({
      where,
      select: expenseSelect(),
      orderBy: { spentAt: 'desc' },
      skip,
      take: limit,
    }),
    prisma.expenseEntry.count({ where }),
  ]);

  return { data, meta: { page, limit, total } };
}

export async function getExpense(userId: string, id: string) {
  const entry = await prisma.expenseEntry.findFirst({
    where: { id, userId },
    select: expenseSelect(),
  });
  if (!entry) throw new NotFoundError('Expense entry not found');
  return entry;
}

export async function createExpense(userId: string, input: CreateExpenseInput) {
  if (input.clientMutationId) {
    const existing = await prisma.expenseEntry.findUnique({
      where: { clientMutationId: input.clientMutationId },
      select: expenseSelect(),
    });
    if (existing) {
      if (existing.userId !== userId) throw new ConflictError('Client mutation ID already used');
      return existing;
    }
  }

  await assertAccountOwned(userId, input.accountId, true);
  await assertCategoryOwned(userId, input.categoryId);
  const spentAt = parseTransactionDate(input.spentAt);

  try {
    return await prisma.expenseEntry.create({
      data: {
        userId,
        accountId: input.accountId,
        categoryId: input.categoryId,
        amount: input.amount,
        description: input.description,
        spentAt,
        status: inferTransactionStatus(spentAt, input.status),
        notes: input.notes,
        clientMutationId: input.clientMutationId,
      },
      select: expenseSelect(),
    });
  } catch (error) {
    // The initial lookup and insert are intentionally separate for the common
    // path. If two retries race, recover the same user's existing mutation
    // instead of leaving an otherwise valid offline item stuck on P2002.
    if (
      input.clientMutationId &&
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      const existing = await prisma.expenseEntry.findUnique({
        where: { clientMutationId: input.clientMutationId },
        select: expenseSelect(),
      });
      if (existing?.userId === userId) return existing;
      throw new ConflictError('Client mutation ID already used');
    }
    throw error;
  }
}

export async function updateExpense(userId: string, id: string, input: UpdateExpenseInput) {
  await getExpense(userId, id);
  if (input.accountId) await assertAccountOwned(userId, input.accountId, true);
  if (input.categoryId) await assertCategoryOwned(userId, input.categoryId);
  const data: any = { ...input };
  if (input.spentAt) {
    data.spentAt = parseTransactionDate(input.spentAt);
    if (!input.status) data.status = inferTransactionStatus(data.spentAt, undefined);
  }
  return prisma.expenseEntry.update({
    where: { id },
    data,
    select: expenseSelect(),
  });
}

export async function deleteExpense(userId: string, id: string) {
  await getExpense(userId, id);
  await prisma.expenseEntry.delete({ where: { id } });
}

export async function getCategorySummary(userId: string, from?: string, to?: string) {
  const where: any = { userId, status: 'posted' };
  if (from || to) {
    where.spentAt = {};
    if (from) where.spentAt.gte = parseDateOnlyStart(from);
    if (to) where.spentAt.lte = parseDateOnlyEnd(to);
  }

  const results = await prisma.expenseEntry.groupBy({
    by: ['categoryId'],
    where,
    _sum: { amount: true },
    _count: { id: true },
    orderBy: { _sum: { amount: 'desc' } },
  });

  // Get category names
  const categoryIds = results.map((r) => r.categoryId);
  const categories = await prisma.expenseCategory.findMany({
    where: {
      id: { in: categoryIds },
      OR: [{ userId }, { userId: null }],
    },
    select: { id: true, name: true, iconKey: true },
  });

  const catMap = new Map(categories.map((c) => [c.id, c]));

  return results.map((r) => ({
    categoryId: r.categoryId,
    categoryName: catMap.get(r.categoryId)?.name || 'Unknown',
    iconKey: catMap.get(r.categoryId)?.iconKey || 'receipt',
    total: toDecimalOrZero(r._sum.amount).toFixed(2),
    count: r._count.id,
  }));
}
