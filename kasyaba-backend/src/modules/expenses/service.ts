import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
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
    notes: true,
    clientMutationId: true,
    createdAt: true,
    updatedAt: true,
  };
}

export async function listExpenses(userId: string, query: Record<string, any>) {
  const where: any = { userId };

  if (query.from || query.to) {
    where.spentAt = {};
    if (query.from) where.spentAt.gte = new Date(query.from);
    if (query.to) where.spentAt.lte = new Date(query.to + 'T23:59:59.999Z');
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
  return prisma.expenseEntry.create({
    data: {
      userId,
      accountId: input.accountId,
      categoryId: input.categoryId,
      amount: input.amount,
      description: input.description,
      spentAt: new Date(input.spentAt),
      notes: input.notes,
      clientMutationId: input.clientMutationId,
    },
    select: expenseSelect(),
  });
}

export async function updateExpense(userId: string, id: string, input: UpdateExpenseInput) {
  await getExpense(userId, id);
  const data: any = { ...input };
  if (input.spentAt) data.spentAt = new Date(input.spentAt);
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
  const where: any = { userId };
  if (from || to) {
    where.spentAt = {};
    if (from) where.spentAt.gte = new Date(from);
    if (to) where.spentAt.lte = new Date(to + 'T23:59:59.999Z');
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
    where: { id: { in: categoryIds } },
    select: { id: true, name: true, iconKey: true },
  });

  const catMap = new Map(categories.map((c) => [c.id, c]));

  return results.map((r) => ({
    categoryId: r.categoryId,
    categoryName: catMap.get(r.categoryId)?.name || 'Unknown',
    iconKey: catMap.get(r.categoryId)?.iconKey || 'receipt',
    total: Number(r._sum.amount).toFixed(2),
    count: r._count.id,
  }));
}
