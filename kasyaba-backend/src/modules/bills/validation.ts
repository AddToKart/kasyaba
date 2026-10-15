import { z } from 'zod';
import { dateOnlySchema, isOrderedRange } from '../../lib/date-schemas';

const amountSchema = z
  .string()
  .regex(/^\d{1,12}(\.\d{1,2})?$/, 'Invalid amount format')
  .refine((value) => Number(value) > 0, 'Amount must be greater than zero');

export const createBillTemplateSchema = z
  .object({
    name: z.string().min(1, 'Bill name is required').max(200),
    defaultAmount: amountSchema,
    categoryId: z.string().uuid().optional(),
    recurrence: z.enum(['none', 'weekly', 'monthly']).default('monthly'),
    dayOfWeek: z.number().int().min(0).max(6).optional(),
    dayOfMonth: z.number().int().min(1).max(31).optional(),
    startsOn: dateOnlySchema,
    endsOn: dateOnlySchema.optional(),
    reminderLeadDays: z.number().int().min(0).max(30).default(1),
    isActive: z.boolean().default(true),
  })
  .refine((value) => isOrderedRange(value.startsOn, value.endsOn), {
    path: ['endsOn'],
    message: 'The end date must be on or after the start date',
  });

export const updateBillTemplateSchema = z
  .object({
    name: z.string().min(1).max(200).optional(),
    defaultAmount: amountSchema.optional(),
    categoryId: z.string().uuid().nullable().optional(),
    recurrence: z.enum(['none', 'weekly', 'monthly']).optional(),
    dayOfWeek: z.number().int().min(0).max(6).nullable().optional(),
    dayOfMonth: z.number().int().min(1).max(31).nullable().optional(),
    startsOn: dateOnlySchema.optional(),
    endsOn: dateOnlySchema.nullable().optional(),
    reminderLeadDays: z.number().int().min(0).max(30).optional(),
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

export const billQuerySchema = z
  .object({
    status: z.enum(['upcoming', 'paid', 'overdue', 'cancelled']).optional(),
    from: dateOnlySchema.optional(),
    to: dateOnlySchema.optional(),
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(500).default(200),
  })
  .refine((value) => !value.from || !value.to || value.to >= value.from, {
    path: ['to'],
    message: 'The end date must be on or after the start date',
  });

export const markPaidSchema = z.object({
  accountId: z.string().uuid('Account ID is required and must be a valid UUID'),
});

export type CreateBillTemplateInput = z.infer<typeof createBillTemplateSchema>;
export type UpdateBillTemplateInput = z.infer<typeof updateBillTemplateSchema>;
