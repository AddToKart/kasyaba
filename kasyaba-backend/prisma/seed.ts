import { PrismaClient } from "@prisma/client";
import { seedDefaultCategories } from "../src/modules/categories/service";
import { seedDemoUser } from "../src/modules/auth/service";

const prisma = new PrismaClient();

// This script creates the known demo account, so it must never touch a
// production database. The API only auto-seeds when SEED_DEMO_USER is enabled
// in development; this guard covers manual `npm run db:seed` runs.
if (process.env.NODE_ENV === "production") {
  console.error(
    "Refusing to seed: NODE_ENV=production. Run this script in development only.",
  );
  process.exit(1);
}

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
