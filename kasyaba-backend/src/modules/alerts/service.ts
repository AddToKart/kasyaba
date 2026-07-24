import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import type { AlertType, AlertSeverity } from '@prisma/client';

export async function listAlerts(userId: string, query: Record<string, any>) {
  const where: any = { userId };

  if (query.status === 'unread') {
    where.readAt = null;
    where.dismissedAt = null;
  }
  if (query.type) where.type = query.type;
  if (query.severity) where.severity = query.severity;

  return prisma.financialAlert.findMany({
    where,
    orderBy: { createdAt: 'desc' },
    take: Math.min(parseInt(query.limit) || 50, 100),
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
    where: { userId, readAt: null },
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
  // Deduplication: update existing unread/resolved alert instead of creating a new one
  const existing = await prisma.financialAlert.findFirst({
    where: {
      userId: params.userId,
      deduplicationKey: params.deduplicationKey,
      resolvedAt: null,
    },
    orderBy: { createdAt: 'desc' },
  });

  if (existing) {
    return prisma.financialAlert.update({
      where: { id: existing.id },
      data: {
        severity: params.severity,
        title: params.title,
        message: params.message,
        reasonData: params.reasonData,
        effectiveDate: params.effectiveDate,
        snapshotId: params.snapshotId,
        updatedAt: new Date(),
      },
    });
  }

  return prisma.financialAlert.create({
    data: {
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
