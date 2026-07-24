import cron from 'node-cron';
import { prisma } from './config/database';
import { env } from './config/env';
import * as forecastingService from './modules/forecasting/service';
import * as billService from './modules/bills/service';

async function runSnapshotJob() {
  console.log('[Worker] Starting daily snapshot job...');

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
        console.error(`[Worker] Failed for user ${user.id}:`, err);
        failed++;
      }

      // Small delay to avoid overwhelming the database
      if (processed % 10 === 0) {
        await new Promise((resolve) => setTimeout(resolve, 100));
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

    console.log(`[Worker] Snapshot job completed: ${processed} processed, ${failed} failed`);
  } catch (err: any) {
    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'failed',
        finishedAt: new Date(),
        errorSummary: err.message,
      },
    });
    console.error('[Worker] Snapshot job failed:', err);
  }
}

async function runBillGenerationJob() {
  console.log('[Worker] Starting bill generation job...');

  const jobRun = await prisma.jobRun.create({
    data: {
      jobName: 'bill_generation',
      status: 'running',
    },
  });

  try {
    const users = await prisma.user.findMany({ select: { id: true } });
    let totalCreated = 0;

    for (const user of users) {
      const created = await billService.generateBillInstances(user.id, 2);
      totalCreated += created;

      const overdueCount = await billService.updateOverdueBills(user.id);
      if (overdueCount > 0) {
        console.log(`[Worker] Marked ${overdueCount} overdue bills for user ${user.id}`);
      }
    }

    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'completed',
        finishedAt: new Date(),
        processedCount: totalCreated,
      },
    });

    console.log(`[Worker] Bill generation completed: ${totalCreated} instances created`);
  } catch (err: any) {
    await prisma.jobRun.update({
      where: { id: jobRun.id },
      data: {
        status: 'failed',
        finishedAt: new Date(),
        errorSummary: err.message,
      },
    });
    console.error('[Worker] Bill generation failed:', err);
  }
}

async function main() {
  console.log(`[Worker] KASYABA Worker started (timezone: ${env.WORKER_TIMEZONE})`);

  // Connect to database
  await prisma.$connect();

  // Schedule daily snapshot
  cron.schedule(env.SNAPSHOT_CRON, () => {
    runSnapshotJob().catch(console.error);
  }, {
    timezone: env.WORKER_TIMEZONE,
  });

  // Schedule bill generation every hour (to catch new templates)
  cron.schedule('0 * * * *', () => {
    runBillGenerationJob().catch(console.error);
  }, {
    timezone: env.WORKER_TIMEZONE,
  });

  console.log(`[Worker] Cron jobs scheduled with timezone ${env.WORKER_TIMEZONE}`);
  console.log(`[Worker] Snapshot cron: ${env.SNAPSHOT_CRON}`);
  console.log(`[Worker] Bill generation cron: 0 * * * *`);

  // Run initial jobs on startup
  console.log('[Worker] Running initial jobs...');
  await runBillGenerationJob();

  // Keep process alive
  process.on('SIGTERM', async () => {
    console.log('[Worker] Shutting down...');
    await prisma.$disconnect();
    process.exit(0);
  });
}

main().catch((err) => {
  console.error('[Worker] Failed to start:', err);
  process.exit(1);
});
