import { z } from 'zod';

export const alertQuerySchema = z.object({
  status: z.enum(['unread']).optional(),
  type: z.enum(['budget_overrun', 'low_balance', 'savings_goal', 'bill_due', 'month_end']).optional(),
  severity: z.enum(['info', 'warning', 'critical']).optional(),
  limit: z.coerce.number().int().positive().max(100).default(50),
});

export type AlertQuery = z.infer<typeof alertQuerySchema>;
