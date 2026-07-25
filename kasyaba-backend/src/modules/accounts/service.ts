import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import { toDecimal } from '../../lib/decimal';
import type { CreateAccountInput, UpdateAccountInput } from './validation';

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
  return prisma.financialAccount.create({
    data: {
      userId,
      name: input.name,
      type: input.type,
      openingBalance: input.openingBalance,
      currencyCode: input.currencyCode,
    },
  });
}

export async function updateAccount(userId: string, accountId: string, input: UpdateAccountInput) {
  await getAccount(userId, accountId);
  return prisma.financialAccount.update({
    where: { id: accountId },
    data: input,
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

  const incomeSum = await prisma.incomeEntry.aggregate({
    where: { accountId, userId },
    _sum: { amount: true },
  });

  const expenseSum = await prisma.expenseEntry.aggregate({
    where: { accountId, userId },
    _sum: { amount: true },
  });

  const balance = toDecimal(account.openingBalance)
    .plus(toDecimal(incomeSum._sum.amount || 0))
    .minus(toDecimal(expenseSum._sum.amount || 0));

  return { accountId: account.id, name: account.name, balance: balance.toFixed(2), currencyCode: account.currencyCode };
}
