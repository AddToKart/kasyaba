import { z } from 'zod';

export const createCategorySchema = z.object({
  name: z.string().min(1, 'Category name is required').max(100),
  iconKey: z.string().max(50).default('receipt'),
});

export const updateCategorySchema = z.object({
  name: z.string().min(1).max(100).optional(),
  iconKey: z.string().max(50).optional(),
});

export type CreateCategoryInput = z.infer<typeof createCategorySchema>;
export type UpdateCategoryInput = z.infer<typeof updateCategorySchema>;
