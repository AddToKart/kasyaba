import { Prisma } from '@prisma/client';
import { prisma } from '../../config/database';
import { parseDateOnlyEnd, parseDateOnlyStart, parseTransactionDate } from '../../lib/transaction-dates';
import { inferTransactionStatus } from '../../lib/transaction-status';
import { ConflictError, NotFoundError } from '../../lib/errors';
import type { CreateTransferInput, TransactionQuery } from './validation';

export interface UnifiedTransaction {
  id: string;
  accountId: string;
  categoryId: string | null;
  amount: string;
  title: string;
  date: Date;
  type: 'expense' | 'income' | 'transfer';
  status: 'planned' | 'posted' | 'cancelled';
  categoryName: string;
  notes: string | null;
}

function buildConditions(
  alias: string,
  dateColumn: string,
  query: TransactionQuery,
  userId: string,
): Prisma.Sql[] {
  const conditions: Prisma.Sql[] = [Prisma.sql`${Prisma.raw(`${alias}."userId"`)} = ${userId}`];
  if (query.from) {
    conditions.push(Prisma.sql`${Prisma.raw(`${alias}."${dateColumn}"`)} >= ${parseDateOnlyStart(query.from)}`);
  }
  if (query.to) {
    conditions.push(Prisma.sql`${Prisma.raw(`${alias}."${dateColumn}"`)} <= ${parseDateOnlyEnd(query.to)}`);
  }
  if (query.accountId) {
    conditions.push(Prisma.sql`${Prisma.raw(`${alias}."accountId"`)} = ${query.accountId}`);
  }
  if (query.status) {
    conditions.push(Prisma.sql`${Prisma.raw(`${alias}."status"`)} = ${query.status}::"TransactionStatus"`);
  }
  return conditions;
}

function buildUnion(userId: string, query: TransactionQuery): Prisma.Sql {
  const expenseConditions = buildConditions('e', 'spentAt', query, userId);
  if (query.categoryId) {
    expenseConditions.push(Prisma.sql`e."categoryId" = ${query.categoryId}`);
  }
  if (query.search) {
    expenseConditions.push(Prisma.sql`e."description" ILIKE ${`%${query.search}%`}`);
  }

  const incomeConditions = buildConditions('i', 'receivedAt', query, userId);
  if (query.search) {
    incomeConditions.push(Prisma.sql`i."source" ILIKE ${`%${query.search}%`}`);
  }

  const transferConditions = buildConditions('t', 'transferredAt', query, userId);
  if (query.search) {
    transferConditions.push(Prisma.sql`t."notes" ILIKE ${`%${query.search}%`}`);
  }

  return Prisma.sql`
    SELECT
      e."id",
      e."accountId",
      e."categoryId",
      e."amount"::text AS "amount",
      e."description" AS "title",
      e."spentAt" AS "date",
      'expense'::text AS "type",
      e."status"::text AS "status",
      c."name" AS "categoryName",
      e."notes"
    FROM "expense_entries" e
    JOIN "expense_categories" c ON c."id" = e."categoryId"
    WHERE ${Prisma.join(expenseConditions, ' AND ')}

    UNION ALL

    SELECT
      i."id",
      i."accountId",
      NULL::text AS "categoryId",
      i."amount"::text AS "amount",
      i."source" AS "title",
      i."receivedAt" AS "date",
      'income'::text AS "type",
      i."status"::text AS "status",
      'Income'::text AS "categoryName",
      i."notes"
    FROM "income_entries" i
    WHERE ${Prisma.join(incomeConditions, ' AND ')}

    UNION ALL

    SELECT
      t."id",
      t."fromAccountId" AS "accountId",
      NULL::text AS "categoryId",
      t."amount"::text AS "amount",
      CONCAT('Transfer to ', to_account."name") AS "title",
      t."transferredAt" AS "date",
      'transfer'::text AS "type",
      t."status"::text AS "status",
      'Transfer'::text AS "categoryName",
      t."notes"
    FROM "account_transfers" t
    JOIN "financial_accounts" to_account ON to_account."id" = t."toAccountId"
    WHERE ${Prisma.join(transferConditions, ' AND ')}
  `;
}

export async function listTransactions(userId: string, query: TransactionQuery) {
  const union = buildUnion(userId, query);
  const skip = (query.page - 1) * query.limit;

  const [data, countRows] = await Promise.all([
    prisma.$queryRaw<UnifiedTransaction[]>(Prisma.sql`
      SELECT * FROM (${union}) entries
      ORDER BY
        CASE "status"
          WHEN 'posted' THEN 0
          WHEN 'planned' THEN 1
          ELSE 2
        END,
        "date" DESC,
        "id" DESC
      OFFSET ${skip}
      LIMIT ${query.limit}
    `),
    prisma.$queryRaw<Array<{ count: number }>>(Prisma.sql`
      SELECT COUNT(*)::int AS count FROM (${union}) entries
    `),
  ]);

  return {
    data,
    meta: { page: query.page, limit: query.limit, total: countRows[0]?.count ?? 0 },
  };
}

export async function createTransfer(userId: string, input: CreateTransferInput) {
  const transferredAt = parseTransactionDate(input.transferredAt);
  const status = inferTransactionStatus(transferredAt, input.status);

  if (input.clientMutationId) {
    const existing = await prisma.accountTransfer.findUnique({
      where: { clientMutationId: input.clientMutationId },
    });
    if (existing) {
      if (existing.userId !== userId) throw new ConflictError('Client mutation ID already used');
      return existing;
    }
  }

  const accounts = await prisma.financialAccount.findMany({
    where: {
      userId,
      id: { in: [input.fromAccountId, input.toAccountId] },
      isArchived: false,
    },
    select: { id: true },
  });
  if (accounts.length !== 2) throw new NotFoundError('Both transfer accounts must be active');

  try {
    return await prisma.accountTransfer.create({
      data: {
        userId,
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        amount: input.amount,
        transferredAt,
        status,
        notes: input.notes,
        clientMutationId: input.clientMutationId,
      },
    });
  } catch (error) {
    if (
      input.clientMutationId &&
      error instanceof Prisma.PrismaClientKnownRequestError &&
      error.code === 'P2002'
    ) {
      const existing = await prisma.accountTransfer.findUnique({
        where: { clientMutationId: input.clientMutationId },
      });
      if (existing?.userId === userId) return existing;
      throw new ConflictError('Client mutation ID already used');
    }
    throw error;
  }
}

export async function deleteTransfer(userId: string, id: string) {
  const transfer = await prisma.accountTransfer.findFirst({
    where: { id, userId },
    select: { id: true },
  });
  if (!transfer) throw new NotFoundError('Transfer not found');
  await prisma.accountTransfer.delete({ where: { id } });
}
