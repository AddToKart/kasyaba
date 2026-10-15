import { z } from 'zod';
import { dateOnlySchema } from '../../lib/date-schemas';

const amountSchema = z
  .string()
  .regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format')
  .refine((value) => Number(value) > 0, 'Amount must be greater than zero');

export const createGoalSchema = z.object({
  name: z.string().min(1, 'Goal name is required').max(200),
  targetAmount: amountSchema,
  targetDate: dateOnlySchema.optional(),
});

export const updateGoalSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  targetAmount: amountSchema.optional(),
  targetDate: dateOnlySchema.nullable().optional(),
  status: z.enum(['active', 'completed', 'paused', 'cancelled']).optional(),
});

export const createContributionSchema = z.object({
  accountId: z.string().uuid().optional(),
  amount: amountSchema,
  contributedAt: z
    .string()
    .datetime({ offset: true })
    .or(dateOnlySchema)
    .default(() => new Date().toISOString()),
  notes: z.string().max(500).optional(),
  // Client-generated idempotency key so offline queue replays cannot
  // double-count a contribution.
  clientMutationId: z.string().min(1).max(128).optional(),
});

export type CreateGoalInput = z.infer<typeof createGoalSchema>;
export type UpdateGoalInput = z.infer<typeof updateGoalSchema>;
export type CreateContributionInput = z.infer<typeof createContributionSchema>;
