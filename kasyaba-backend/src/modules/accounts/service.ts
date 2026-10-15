import { prisma } from '../../config/database';
import { NotFoundError, ValidationError } from '../../lib/errors';
import { toDecimal } from '../../lib/decimal';
import type { CreateAccountInput, UpdateAccountInput } from './validation';

/**
 * Multi-currency accounts are not supported yet: balances and forecasts sum
 * across accounts, so a non-base currency would silently corrupt totals.
 */
async function assertBaseCurrency(userId: string, currencyCode: string): Promise<string> {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { currencyCode: true },
  });
  const base = (user?.currencyCode ?? 'PHP').toUpperCase();
  const requested = currencyCode.toUpperCase();
  if (requested !== base) {
    throw new ValidationError(
      `Only ${base} accounts are supported right now.`,
      { currencyCode: `Only ${base} accounts are supported right now.` },
    );
  }
  return requested;
}

export async function listAccounts(userId: string) {
  return prisma.financialAccount.findMany({
    where: { userId, isArchived: false },
    orderBy: { createdAt: 'asc' },
  });
}

export async function getAccount(userId: string, accountId: string) {
  const account = await prisma.financialAccount.findFirst({
    where: { id: accountId, userId },
  });
  if (!account) throw new NotFoundError('Account not found');
  return account;
}

export async function createAccount(userId: string, input: CreateAccountInput) {
  const currencyCode = await assertBaseCurrency(userId, input.currencyCode);
  return prisma.financialAccount.create({
    data: {
      userId,
      name: input.name,
      type: input.type,
      openingBalance: input.openingBalance,
      currencyCode,
    },
  });
}

export async function updateAccount(userId: string, accountId: string, input: UpdateAccountInput) {
  await getAccount(userId, accountId);
  const currencyCode = input.currencyCode
    ? await assertBaseCurrency(userId, input.currencyCode)
    : undefined;
  return prisma.financialAccount.update({
    where: { id: accountId },
    data: { ...input, ...(currencyCode ? { currencyCode } : {}) },
  });
}

export async function archiveAccount(userId: string, accountId: string) {
  await getAccount(userId, accountId);
  return prisma.financialAccount.update({
    where: { id: accountId },
    data: { isArchived: true },
  });
}

export async function getAccountBalance(userId: string, accountId: string) {
  const account = await getAccount(userId, accountId);
  const now = new Date();

  const incomeSum = await prisma.incomeEntry.aggregate({
    where: { accountId, userId, status: 'posted', receivedAt: { lte: now } },
    _sum: { amount: true },
  });

  const expenseSum = await prisma.expenseEntry.aggregate({
    where: { accountId, userId, status: 'posted', spentAt: { lte: now } },
    _sum: { amount: true },
  });

  const savingsSum = await prisma.savingsContribution.aggregate({
    where: { accountId, userId, contributedAt: { lte: now } },
    _sum: { amount: true },
  });

  const [outgoingTransfers, incomingTransfers] = await Promise.all([
    prisma.accountTransfer.aggregate({
      where: { fromAccountId: accountId, userId, status: 'posted', transferredAt: { lte: now } },
      _sum: { amount: true },
    }),
    prisma.accountTransfer.aggregate({
      where: { toAccountId: accountId, userId, status: 'posted', transferredAt: { lte: now } },
      _sum: { amount: true },
    }),
  ]);

  const balance = toDecimal(account.openingBalance)
    .plus(toDecimal(incomeSum._sum.amount || 0))
    .minus(toDecimal(expenseSum._sum.amount || 0))
    .minus(toDecimal(savingsSum._sum.amount || 0))
    .minus(toDecimal(outgoingTransfers._sum.amount || 0))
    .plus(toDecimal(incomingTransfers._sum.amount || 0));

  return { accountId: account.id, name: account.name, balance: balance.toFixed(2), currencyCode: account.currencyCode };
}
