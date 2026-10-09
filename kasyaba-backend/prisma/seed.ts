import { PrismaClient } from "@prisma/client";
import { seedDefaultCategories } from "../src/modules/categories/service";
import { seedDemoUser } from "../src/modules/auth/service";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database...");
  await seedDefaultCategories();
  await seedDemoUser();
  console.log("Default categories and demo user seeded");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
