import { z } from 'zod';

export const createBillTemplateSchema = z.object({
  name: z.string().min(1, 'Bill name is required').max(200),
  defaultAmount: z.string().regex(/^\d+(\.\d{1,2})?$/, 'Invalid amount format'),
  categoryId: z.string().uuid().optional(),
  recurrence: z.enum(['none', 'weekly', 'monthly']).default('monthly'),
  dayOfWeek: z.number().int().min(0).max(6).optional(),
  dayOfMonth: z.number().int().min(1).max(31).optional(),
  startsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/),
  endsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/).optional(),
  reminderLeadDays: z.number().int().min(0).max(30).default(1),
  isActive: z.boolean().default(true),
});

export const updateBillTemplateSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  defaultAmount: z.string().regex(/^\d+(\.\d{1,2})?$/).optional(),
  categoryId: z.string().uuid().nullable().optional(),
  recurrence: z.enum(['none', 'weekly', 'monthly']).optional(),
  dayOfWeek: z.number().int().min(0).max(6).nullable().optional(),
  dayOfMonth: z.number().int().min(1).max(31).nullable().optional(),
  startsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/).optional(),
  endsOn: z.string().regex(/^\d{4}-\d{2}-\d{2}/).nullable().optional(),
  reminderLeadDays: z.number().int().min(0).max(30).optional(),
  isActive: z.boolean().optional(),
});

export const billQuerySchema = z.object({
  status: z.enum(['upcoming', 'paid', 'overdue', 'cancelled']).optional(),
  from: z.string().regex(/^\d{4}-\d{2}-\d{2}/).optional(),
  to: z.string().regex(/^\d{4}-\d{2}-\d{2}/).optional(),
});

export type CreateBillTemplateInput = z.infer<typeof createBillTemplateSchema>;
export type UpdateBillTemplateInput = z.infer<typeof updateBillTemplateSchema>;
