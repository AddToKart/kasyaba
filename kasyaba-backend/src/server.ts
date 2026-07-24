import { createApp } from './app';
import { env } from './config/env';
import { prisma } from './config/database';

async function main() {
  const app = createApp();

  // Connect to database
  await prisma.$connect();
  console.log('Database connected');

  // Seed default categories
  const { seedDefaultCategories } = await import('./modules/categories/service');
  await seedDefaultCategories();
  console.log('Default categories seeded');

  const server = app.listen(env.PORT, () => {
    console.log(`KASYABA API running on port ${env.PORT}`);
  });

  // Graceful shutdown
  const shutdown = async () => {
    console.log('Shutting down gracefully...');
    server.close(async () => {
      await prisma.$disconnect();
      process.exit(0);
    });
    // Force shutdown after 10s
    setTimeout(() => process.exit(1), 10000);
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

main().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
