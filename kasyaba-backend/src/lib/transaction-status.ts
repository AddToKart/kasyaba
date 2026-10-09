import type { TransactionStatus } from '@prisma/client';

export function inferTransactionStatus(
  date: Date,
  status: TransactionStatus | undefined,
): TransactionStatus {
  if (status) return status;
  return date.getTime() > Date.now() ? 'planned' : 'posted';
}
