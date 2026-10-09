import { createApp, logger } from "./app";
import { env } from "./config/env";
import { prisma } from "./config/database";
import { seedDefaultCategories } from "./modules/categories/service";
import { seedDemoUser } from "./modules/auth/service";

async function main() {
  const app = createApp();

  // Connect to database
  await prisma.$connect();
  logger.info("Database connected");

  // Seed default categories
  await seedDefaultCategories();
  logger.info("Default categories seeded");

  // Seed demo user only when explicitly requested in development
  if (env.NODE_ENV === "development" && env.SEED_DEMO_USER) {
    await seedDemoUser();
    logger.info("Demo user seeded");
  }

  const server = app.listen(env.PORT, () => {
    logger.info({ port: env.PORT }, "KASYABA API running");
  });

  // Graceful shutdown
  const shutdown = async () => {
    logger.info("Shutting down gracefully...");
    server.close(async () => {
      await prisma.$disconnect();
      process.exit(0);
    });
    // Force shutdown after 10s
    setTimeout(() => process.exit(1), 10000);
  };

  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
}

main().catch((err) => {
  logger.fatal({ err }, "Failed to start server");
  process.exit(1);
});
