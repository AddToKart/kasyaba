import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');

  // Seed default categories
  const defaultCategories = [
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

  for (const cat of defaultCategories) {
    const existing = await prisma.expenseCategory.findFirst({
      where: { userId: null, name: cat.name },
    });
    if (!existing) {
      await prisma.expenseCategory.create({
        data: { name: cat.name, iconKey: cat.iconKey },
      });
    }
  }

  console.log('Default categories seeded');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
