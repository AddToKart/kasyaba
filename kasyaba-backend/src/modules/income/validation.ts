import { z } from 'zod';
import { isValidTransactionDate } from '../../lib/transaction-dates';

const transactionDateSchema = z.string().refine(isValidTransactionDate, 'Invalid transaction date');
const dateOnlySchema = z.string().refine((value) => {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) && isValidTransactionDate(value);
}, 'Invalid calendar date');
const transactionStatusSchema = z.enum(['planned', 'posted', 'cancelled']);

export const createIncomeSchema = z.object({
  accountId: z.string().uuid(),
  amount: z.string().regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format')
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero'),
  source: z.string().min(1, 'Source is required').max(200),
  receivedAt: transactionDateSchema,
  status: transactionStatusSchema.optional(),
  notes: z.string().max(500).optional(),
  clientMutationId: z.string().uuid().optional(),
});

export const updateIncomeSchema = z.object({
  accountId: z.string().uuid().optional(),
  amount: z.string().regex(/^\d{1,12}(\.\d{1,2})?$/)
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero').optional(),
  source: z.string().min(1).max(200).optional(),
  receivedAt: transactionDateSchema.optional(),
  status: transactionStatusSchema.optional(),
  notes: z.string().max(500).optional(),
});

export const incomeQuerySchema = z.object({
  from: dateOnlySchema.optional(),
  to: dateOnlySchema.optional(),
  source: z.string().optional(),
  accountId: z.string().uuid().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
}).refine((value) => !value.from || !value.to || value.from <= value.to, {
  path: ['to'],
  message: 'The end date must be on or after the start date',
});

export type CreateIncomeInput = z.infer<typeof createIncomeSchema>;
export type UpdateIncomeInput = z.infer<typeof updateIncomeSchema>;
