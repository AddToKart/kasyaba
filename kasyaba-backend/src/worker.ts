import cron from 'node-cron';
import { prisma } from './config/database';
import { env } from './config/env';
import { logger } from './app';
import * as forecastingService from './modules/forecasting/service';
import * as billService from './modules/bills/service';

async function runSnapshotJob() {
  logger.info('Starting daily snapshot job...');

  const jobRun = await prisma.jobRun.create({
    data: {
      jobName: 'daily_snapshot',
      status: 'running',
    },
  });

  try {
    const users = await prisma.user.findMany({ select: { id: true } });
    let processed = 0;
    let failed = 0;

    for (const user of users) {
      try {
        await forecastingService.createDailySnapshot(user.id);
        await forecastingService.generateAlertsFromSnapshot(user.id);
        processed++;
      } catch (err) {
        logger.error({ err, userId: user.id }, 'Snapshot failed for user');
        failed++;
      }

      // Small delay to avoid overwhelming the database
      if (processed % 10 === 0) {
        const { promise, resolve } = Promise.withResolvers<void>();
        setTimeout(resolve, 100);
        await promise;
      }
    }

    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'completed',
        finishedAt: new Date(),
        processedCount: processed,
        failedCount: failed,
      },
    });

    logger.info({ processed, failed }, 'Snapshot job completed');
  } catch (err) {
    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'failed',
        finishedAt: new Date(),
        errorSummary: err instanceof Error ? err.message : String(err),
      },
    });
    logger.error({ err }, 'Snapshot job failed');
  }
}

async function runBillGenerationJob() {
  logger.info('Starting bill generation job...');

  const jobRun = await prisma.jobRun.create({
    data: {
      jobName: 'bill_generation',
      status: 'running',
    },
  });

  try {
    const users = await prisma.user.findMany({ select: { id: true } });
    let totalCreated = 0;
    let failed = 0;

    for (const user of users) {
      try {
        const created = await billService.generateBillInstances(user.id);
        await billService.updateOverdueBills(user.id);
        totalCreated += created;
      } catch (err) {
        logger.error({ err, userId: user.id }, 'Bill generation failed for user');
        failed++;
      }
    }

    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'completed',
        finishedAt: new Date(),
        processedCount: totalCreated,
        failedCount: failed,
      },
    });

    logger.info({ totalCreated, failed }, 'Bill generation job completed');
  } catch (err) {
    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'failed',
        finishedAt: new Date(),
        errorSummary: err instanceof Error ? err.message : String(err),
      },
    });
    logger.error({ err }, 'Bill generation job failed');
  }
}

async function main() {
  logger.info({ timezone: env.WORKER_TIMEZONE }, 'KASYABA Worker started');

  // Connect to database
  await prisma.$connect();

  // Schedule daily snapshot
  cron.schedule(env.SNAPSHOT_CRON, () => {
    runSnapshotJob().catch((err) => logger.error({ err }, 'Snapshot cron failed'));
  }, {
    timezone: env.WORKER_TIMEZONE,
  });

  // Schedule bill generation every hour (to catch new templates)
  cron.schedule('0 * * * *', () => {
    runBillGenerationJob().catch((err) => logger.error({ err }, 'Bill gen cron failed'));
  }, {
    timezone: env.WORKER_TIMEZONE,
  });

  logger.info({ snapshotCron: env.SNAPSHOT_CRON, billGenCron: '0 * * * *' }, 'Cron jobs scheduled');

  // Run initial jobs on startup
  logger.info('Running initial jobs...');
  await runBillGenerationJob();

  // Keep process alive
  process.on('SIGTERM', async () => {
    logger.info('Worker shutting down...');
    await prisma.$disconnect();
    process.exit(0);
  });
}

main().catch((err) => {
  logger.fatal({ err }, 'Failed to start worker');
  process.exit(1);
});
