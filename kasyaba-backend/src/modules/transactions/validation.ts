import { z } from 'zod';
import { isValidTransactionDate } from '../../lib/transaction-dates';

const dateOnlySchema = z.string().refine((value) => {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) && isValidTransactionDate(value);
}, 'Invalid calendar date');

export const transactionQuerySchema = z.object({
  from: dateOnlySchema.optional(),
  to: dateOnlySchema.optional(),
  accountId: z.string().uuid().optional(),
  categoryId: z.string().uuid().optional(),
  search: z.string().trim().max(100).optional(),
  status: z.enum(['planned', 'posted', 'cancelled']).optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
}).refine((value) => !value.from || !value.to || value.from <= value.to, {
  path: ['to'],
  message: 'The end date must be on or after the start date',
});

export type TransactionQuery = z.infer<typeof transactionQuerySchema>;

export const createTransferSchema = z.object({
  fromAccountId: z.string().uuid(),
  toAccountId: z.string().uuid(),
  amount: z.string().regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format')
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero'),
  transferredAt: z.string().refine(isValidTransactionDate, 'Invalid transfer date'),
  status: z.enum(['planned', 'posted', 'cancelled']).optional(),
  notes: z.string().max(1000).optional(),
  clientMutationId: z.string().uuid().optional(),
}).refine((value) => value.fromAccountId !== value.toAccountId, {
  path: ['toAccountId'],
  message: 'A transfer must use two different accounts',
});

export type CreateTransferInput = z.infer<typeof createTransferSchema>;
