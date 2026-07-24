import { z } from 'zod';

export const createBudgetSchema = z.object({
  categoryId: z.string().uuid().nullable().optional(),
  period: z.enum(['monthly']).default('monthly'),
  amount: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Invalid amount format'),
  startsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/),
  endsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/).nullable().optional(),
  isActive: z.boolean().default(true),
});

export const updateBudgetSchema = z.object({
  categoryId: z.string().uuid().nullable().optional(),
  amount: z.string().regex(/^\d+(\.\d{1,2})?$/).optional(),
  startsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/).optional(),
  endsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/).nullable().optional(),
  isActive: z.boolean().optional(),
});

export const budgetStatusSchema = z.object({
  month: z.string().regex(/^\d{4}-\d{2}$/, 'Use YYYY-MM format'),
});

export type CreateBudgetInput = z.infer<typeof createBudgetSchema>;
export type UpdateBudgetInput = z.infer<typeof updateBudgetSchema>;
