import { z } from 'zod';

export const createGoalSchema = z.object({
  name: z.string().min(1, 'Goal name is required').max(200),
  targetAmount: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Invalid amount format'),
  targetDate: z.string().regex(/^\d{4}-\d{2}-\d{2}/).optional(),
});

export const updateGoalSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  targetAmount: z.string().regex(/^\d+(\.\d{1,2})?$/).optional(),
  targetDate: z.string().regex(/^\d{4}-\d{2}-\d{2}/).nullable().optional(),
  status: z.enum(['active', 'completed', 'paused', 'cancelled']).optional(),
});

export const createContributionSchema = z.object({
  accountId: z.string().uuid().optional(),
  amount: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Invalid amount format'),
  contributedAt: z.string().datetime({ offset: true }).or(z.string().regex(/^\d{4}-\d{2}-\d{2}/)).default(() => new Date().toISOString()),
  notes: z.string().max(500).optional(),
});

export type CreateGoalInput = z.infer<typeof createGoalSchema>;
export type UpdateGoalInput = z.infer<typeof updateGoalSchema>;
export type CreateContributionInput = z.infer<typeof createContributionSchema>;
