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
  for (const cat of DEFAULT_CATEGORIES) {
    await prisma.expenseCategory.upsert({
      where: { userId_name: { userId: null as any, name: cat.name } },
      update: {},
      create: { name: cat.name, iconKey: cat.iconKey },
    });
  }
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
