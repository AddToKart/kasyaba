import { z } from 'zod';

export const createAccountSchema = z.object({
  name: z.string().min(1, 'Account name is required').max(100),
  type: z.enum(['cash', 'bank', 'ewallet', 'other']).default('cash'),
  openingBalance: z.string().regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format').default('0'),
  currencyCode: z.string().length(3).default('PHP'),
});

export const updateAccountSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  type: z.enum(['cash', 'bank', 'ewallet', 'other']).optional(),
  currencyCode: z.string().length(3).optional(),
});

export type CreateAccountInput = z.infer<typeof createAccountSchema>;
export type UpdateAccountInput = z.infer<typeof updateAccountSchema>;
