import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import { logger } from '../../lib/logger';
import { withUserThrottle } from '../../lib/user-cache';
import type { AlertType, AlertSeverity } from '@prisma/client';
import { generateAlertsFromSnapshot } from '../forecasting/service';

export async function listAlerts(userId: string, query: Record<string, any>) {
  // Re-evaluate alerts at most once per short window. Mutating requests clear
  // the window, so a freshly changed budget/transaction is still reflected on
  // the next read, while rapid tab switches no longer trigger a full
  // recomputation every time. Failures are logged and never break reads.
  await withUserThrottle(`alerts:${userId}`, () =>
    generateAlertsFromSnapshot(userId),
  ).catch((err) => {
    logger.error({ err, userId }, 'Alert evaluation failed');
  });

  const where: any = { userId };

  if (query.status === 'unread') {
    where.readAt = null;
    where.dismissedAt = null;
    where.resolvedAt = null;
  }
  if (query.type) where.type = query.type;
  if (query.severity) where.severity = query.severity;

  return prisma.financialAlert.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: Math.min(query.limit || 50, 100),
  });
}

export async function markAlertRead(userId: string, alertId: string) {
  const alert = await prisma.financialAlert.findFirst({ where: { id: alertId, userId } });
  if (!alert) throw new NotFoundError('Alert not found');
  return prisma.financialAlert.update({
    where: { id: alertId },
    data: { readAt: new Date() },
  });
}

export async function dismissAlert(userId: string, alertId: string) {
  const alert = await prisma.financialAlert.findFirst({ where: { id: alertId, userId } });
  if (!alert) throw new NotFoundError('Alert not found');
  return prisma.financialAlert.update({
    where: { id: alertId },
    data: { dismissedAt: new Date() },
  });
}

export async function readAllAlerts(userId: string) {
  await prisma.financialAlert.updateMany({
    where: { userId, readAt: null, resolvedAt: null },
    data: { readAt: new Date() },
  });
}

export async function createAlert(params: {
  userId: string;
  snapshotId?: string;
  type: AlertType;
  severity: AlertSeverity;
  title: string;
  message: string;
  reasonData?: any;
  effectiveDate: Date;
  deduplicationKey: string;
}) {
  // The compound unique key makes this safe when the worker and an API read
  // evaluate the same alert concurrently. Read/dismissed state is preserved:
  // regenerating an active alert must not resurface it as unread.
  return prisma.financialAlert.upsert({
    where: {
      userId_deduplicationKey: {
        userId: params.userId,
        deduplicationKey: params.deduplicationKey,
      },
    },
    update: {
      severity: params.severity,
      title: params.title,
      message: params.message,
      reasonData: params.reasonData,
      effectiveDate: params.effectiveDate,
      snapshotId: params.snapshotId,
      updatedAt: new Date(),
      resolvedAt: null,
    },
    create: {
      userId: params.userId,
      snapshotId: params.snapshotId,
      type: params.type,
      severity: params.severity,
      title: params.title,
      message: params.message,
      reasonData: params.reasonData,
      effectiveDate: params.effectiveDate,
      deduplicationKey: params.deduplicationKey,
    },
  });
}

export async function resolveAlertsByKey(userId: string, deduplicationKeyPrefix: string) {
  await prisma.financialAlert.updateMany({
    where: {
      userId,
      deduplicationKey: { startsWith: deduplicationKeyPrefix },
      resolvedAt: null,
    },
    data: { resolvedAt: new Date() },
  });
}
