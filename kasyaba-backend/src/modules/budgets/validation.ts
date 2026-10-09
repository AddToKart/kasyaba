import { z } from 'zod';
import { dateOnlySchema, isOrderedRange } from '../../lib/date-schemas';

const amountSchema = z
  .string()
  .regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format')
  .refine((value) => Number(value) > 0, 'Amount must be greater than zero');

export const createBudgetSchema = z
  .object({
    categoryId: z.string().uuid().nullable().optional(),
    period: z.enum(['monthly']).default('monthly'),
    amount: amountSchema,
    startsOn: dateOnlySchema,
    endsOn: dateOnlySchema.nullable().optional(),
    isActive: z.boolean().default(true),
  })
  .refine((value) => isOrderedRange(value.startsOn, value.endsOn), {
    path: ['endsOn'],
    message: 'The end date must be on or after the start date',
  });

export const updateBudgetSchema = z
  .object({
    categoryId: z.string().uuid().nullable().optional(),
    amount: amountSchema.optional(),
    startsOn: dateOnlySchema.optional(),
    endsOn: dateOnlySchema.nullable().optional(),
    isActive: z.boolean().optional(),
  })
  .refine(
    (value) =>
      value.startsOn === undefined ||
      value.endsOn === undefined ||
      isOrderedRange(value.startsOn, value.endsOn),
    {
      path: ['endsOn'],
      message: 'The end date must be on or after the start date',
    },
  );

export const budgetStatusSchema = z.object({
  month: z.string().regex(/^\d{4}-(0[1-9]|1[0-2])$/, 'Use YYYY-MM format'),
});

export type CreateBudgetInput = z.infer<typeof createBudgetSchema>;
export type UpdateBudgetInput = z.infer<typeof updateBudgetSchema>;
