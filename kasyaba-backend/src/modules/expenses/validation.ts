import { z } from 'zod';
import { isValidTransactionDate } from '../../lib/transaction-dates';

const transactionDateSchema = z.string().refine(isValidTransactionDate, 'Invalid transaction date');
const dateOnlySchema = z.string().refine((value) => {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) && isValidTransactionDate(value);
}, 'Invalid calendar date');
const transactionStatusSchema = z.enum(['planned', 'posted', 'cancelled']);

export const createExpenseSchema = z.object({
  accountId: z.string().uuid(),
  categoryId: z.string().uuid(),
  amount: z.string().regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format')
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero'),
  description: z.string().min(1, 'Description is required').max(500),
  spentAt: transactionDateSchema,
  status: transactionStatusSchema.optional(),
  notes: z.string().max(1000).optional(),
  clientMutationId: z.string().uuid().optional(),
});

export const updateExpenseSchema = z.object({
  accountId: z.string().uuid().optional(),
  categoryId: z.string().uuid().optional(),
  amount: z.string().regex(/^\d{1,12}(\.\d{1,2})?$/)
    .refine((value) => Number(value) > 0, 'Amount must be greater than zero').optional(),
  description: z.string().min(1).max(500).optional(),
  spentAt: transactionDateSchema.optional(),
  status: transactionStatusSchema.optional(),
  notes: z.string().max(1000).optional(),
});

export const expenseQuerySchema = z.object({
  from: dateOnlySchema.optional(),
  to: dateOnlySchema.optional(),
  categoryId: z.string().uuid().optional(),
  accountId: z.string().uuid().optional(),
  search: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(20),
}).refine((value) => !value.from || !value.to || value.from <= value.to, {
  path: ['to'],
  message: 'The end date must be on or after the start date',
});

export const categorySummarySchema = z.object({
  from: dateOnlySchema.optional(),
  to: dateOnlySchema.optional(),
});

export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;
export type UpdateExpenseInput = z.infer<typeof updateExpenseSchema>;
