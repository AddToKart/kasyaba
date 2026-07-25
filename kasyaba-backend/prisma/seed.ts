import { PrismaClient } from '@prisma/client';
import { seedDefaultCategories } from '../src/modules/categories/service';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database...');
  await seedDefaultCategories();
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
