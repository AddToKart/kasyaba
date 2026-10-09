import { z } from 'zod';
import { isValidTransactionDate, parseTransactionDate } from '../../lib/transaction-dates';

const dateOnlySchema = z.string().refine((value) => {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) && isValidTransactionDate(value);
}, 'Invalid calendar date');

export const planningQuerySchema = z.object({
  from: dateOnlySchema.optional(),
  to: dateOnlySchema.optional(),
}).superRefine((value, ctx) => {
  if (!value.from || !value.to) return;
  const from = parseTransactionDate(value.from).getTime();
  const to = parseTransactionDate(value.to).getTime();
  if (to < from) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['to'], message: 'The end date must be on or after the start date' });
  }
  if (to - from > 90 * 24 * 60 * 60 * 1000) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ['to'], message: 'Planning windows cannot exceed 91 days' });
  }
});

export type PlanningQuery = z.infer<typeof planningQuerySchema>;
