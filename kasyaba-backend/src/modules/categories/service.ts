import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import type { CreateCategoryInput, UpdateCategoryInput } from './validation';

// Default system categories (no userId)
const DEFAULT_CATEGORIES = [
  { name: 'Food', iconKey: 'restaurant' },
  { name: 'Transportation', iconKey: 'directions_car' },
  { name: 'Utilities', iconKey: 'bolt' },
  { name: 'Rent', iconKey: 'home' },
  { name: 'Education', iconKey: 'school' },
  { name: 'Healthcare', iconKey: 'local_hospital' },
  { name: 'Entertainment', iconKey: 'movie' },
  { name: 'Shopping', iconKey: 'shopping_cart' },
  { name: 'Other', iconKey: 'receipt' },
];

export async function seedDefaultCategories() {
  // `skipDuplicates` emits ON CONFLICT DO NOTHING. It is only idempotent
  // because migration 20260827000000 adds a partial unique index on (name)
  // for system categories (userId IS NULL); PostgreSQL otherwise treats NULLs
  // as distinct and would insert a fresh set on every server start.
  await prisma.expenseCategory.createMany({
    data: DEFAULT_CATEGORIES,
    skipDuplicates: true,
  });
}

export async function listCategories(userId: string) {
  return prisma.expenseCategory.findMany({
    where: {
      OR: [
        { userId: null },
        { userId },
      ],
      isArchived: false,
    },
    orderBy: [{ userId: { sort: 'asc', nulls: 'first' } }, { name: 'asc' }],
  });
}

export async function createCategory(userId: string, input: CreateCategoryInput) {
  return prisma.expenseCategory.create({
    data: {
      userId,
      name: input.name,
      iconKey: input.iconKey,
    },
  });
}

export async function updateCategory(userId: string, categoryId: string, input: UpdateCategoryInput) {
  const cat = await prisma.expenseCategory.findFirst({
    where: { id: categoryId, userId },
  });
  if (!cat) throw new NotFoundError('Category not found');
  return prisma.expenseCategory.update({
    where: { id: categoryId },
    data: input,
  });
}

export async function archiveCategory(userId: string, categoryId: string) {
  const cat = await prisma.expenseCategory.findFirst({
    where: { id: categoryId, userId },
  });
  if (!cat) throw new NotFoundError('Category not found');
  return prisma.expenseCategory.update({
    where: { id: categoryId },
    data: { isArchived: true },
  });
}
