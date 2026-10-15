import cron from 'node-cron';
import { prisma } from './config/database';
import { env } from './config/env';
import { logger } from './lib/logger';
import * as forecastingService from './modules/forecasting/service';
import * as billService from './modules/bills/service';

const USER_BATCH_SIZE = 200;
const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

let snapshotJobRunning = false;
let billGenerationJobRunning = false;

/**
 * Iterates all users with keyset pagination so the worker never loads the
 * whole user table into memory. A failure for one user does not abort the run.
 */
async function forEachUserBatch(
  jobName: string,
  handler: (userId: string) => Promise<void>,
): Promise<{ processed: number; failed: number }> {
  let processed = 0;
  let failed = 0;
  let cursor: string | undefined;

  for (;;) {
    const users = await prisma.user.findMany({
      select: { id: true },
      orderBy: { id: 'asc' },
      take: USER_BATCH_SIZE,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    });
    if (users.length === 0) break;

    for (const user of users) {
      try {
        await handler(user.id);
        processed++;
      } catch (err) {
        logger.error({ err, userId: user.id, job: jobName }, 'Job failed for user');
        failed++;
      }
    }

    if (users.length < USER_BATCH_SIZE) break;
    cursor = users[users.length - 1].id;
    // Small pause between batches to avoid saturating the database.
    await delay(50);
  }

  return { processed, failed };
}

async function startJobRun(jobName: string): Promise<string | null> {
  try {
    const jobRun = await prisma.jobRun.create({
      data: { jobName, status: 'running' },
    });
    return jobRun.id;
  } catch (err) {
    logger.error({ err, jobName }, 'Failed to create job run record');
    return null;
  }
}

async function finishJobRun(
  jobRunId: string | null,
  data: {
    status: 'completed' | 'failed';
    processedCount?: number;
    failedCount?: number;
    errorSummary?: string;
  },
) {
  if (!jobRunId) return;
  try {
    await prisma.jobRun.update({
      where: { id: jobRunId },
      data: { ...data, finishedAt: new Date() },
    });
  } catch (err) {
    logger.error({ err, jobRunId }, 'Failed to update job run record');
  }
}

async function runSnapshotJob() {
  if (snapshotJobRunning) {
    logger.warn('Snapshot job skipped: previous run still in progress');
    return;
  }
  snapshotJobRunning = true;
  logger.info('Starting daily snapshot job...');
  const jobRunId = await startJobRun('daily_snapshot');

  try {
    const { processed, failed } = await forEachUserBatch(
      'daily_snapshot',
      async (userId) => {
        await forecastingService.createDailySnapshot(userId);
        await forecastingService.generateAlertsFromSnapshot(userId);
      },
    );

    await finishJobRun(jobRunId, {
      status: 'completed',
      processedCount: processed,
      failedCount: failed,
    });
    logger.info({ processed, failed }, 'Snapshot job completed');
  } catch (err) {
    await finishJobRun(jobRunId, {
      status: 'failed',
      errorSummary: err instanceof Error ? err.message : String(err),
    });
    logger.error({ err }, 'Snapshot job failed');
  } finally {
    snapshotJobRunning = false;
  }
}

async function runBillGenerationJob() {
  if (billGenerationJobRunning) {
    logger.warn('Bill generation job skipped: previous run still in progress');
    return;
  }
  billGenerationJobRunning = true;
  logger.info('Starting bill generation job...');
  const jobRunId = await startJobRun('bill_generation');

  try {
    let totalCreated = 0;
    const { failed } = await forEachUserBatch('bill_generation', async (userId) => {
      totalCreated += await billService.generateBillInstances(userId);
      await billService.updateOverdueBills(userId);
    });

    await finishJobRun(jobRunId, {
      status: 'completed',
      processedCount: totalCreated,
      failedCount: failed,
    });
    logger.info({ totalCreated, failed }, 'Bill generation job completed');
  } catch (err) {
    await finishJobRun(jobRunId, {
      status: 'failed',
      errorSummary: err instanceof Error ? err.message : String(err),
    });
    logger.error({ err }, 'Bill generation job failed');
  } finally {
    billGenerationJobRunning = false;
  }
}

/**
 * A worker restart can leave `running` rows behind. Mark them failed so
 * operational dashboards never show permanently in-progress jobs.
 */
async function reconcileInterruptedJobs() {
  const result = await prisma.jobRun.updateMany({
    where: { status: 'running' },
    data: {
      status: 'failed',
      finishedAt: new Date(),
      errorSummary: 'Interrupted by worker restart',
    },
  });
  if (result.count > 0) {
    logger.warn({ count: result.count }, 'Marked interrupted job runs as failed');
  }
}

async function main() {
  logger.info({ timezone: env.WORKER_TIMEZONE }, 'KASYABA Worker started');

  // Connect to database
  await prisma.$connect();
  await reconcileInterruptedJobs();

  // Schedule daily snapshot
  cron.schedule(
    env.SNAPSHOT_CRON,
    () => {
      runSnapshotJob().catch((err) => logger.error({ err }, 'Snapshot cron failed'));
    },
    { timezone: env.WORKER_TIMEZONE },
  );

  // Schedule bill generation every hour (to catch new templates)
  cron.schedule(
    '0 * * * *',
    () => {
      runBillGenerationJob().catch((err) => logger.error({ err }, 'Bill gen cron failed'));
    },
    { timezone: env.WORKER_TIMEZONE },
  );

  logger.info(
    { snapshotCron: env.SNAPSHOT_CRON, billGenCron: '0 * * * *' },
    'Cron jobs scheduled',
  );

  // Run initial bill generation on startup
  logger.info('Running initial bill generation...');
  await runBillGenerationJob();

  const shutdown = async (signal: string) => {
    logger.info({ signal }, 'Worker shutting down...');
    await prisma.$disconnect();
    process.exit(0);
  };
  process.on('SIGTERM', () => void shutdown('SIGTERM'));
  process.on('SIGINT', () => void shutdown('SIGINT'));
}

main().catch((err) => {
  logger.fatal({ err }, 'Failed to start worker');
  process.exit(1);
});
