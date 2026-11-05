import { prisma } from '../../config/database';

export const SESSION_PRUNE_BATCH_SIZE = 1000;
export const REVOKED_SESSION_RETENTION_DAYS = 30;
const BATCH_PAUSE_MS = 50;

const delay = (ms: number) => new Promise<void>((resolve) => setTimeout(resolve, ms));

/**
 * Sessions revoked more than [REVOKED_SESSION_RETENTION_DAYS] days before
 * [now] are safe to delete. Revoked rows are kept briefly for abuse
 * investigation; expired rows are deleted immediately.
 */
export function revokedSessionCutoff(now: Date): Date {
  return new Date(
    now.getTime() - REVOKED_SESSION_RETENTION_DAYS * 24 * 60 * 60 * 1000,
  );
}

/**
 * Deletes sessions that can no longer authenticate anyone:
 *   - expired sessions (expiresAt < now), and
 *   - sessions revoked more than 30 days ago.
 *
 * The predicate is idempotent, so a crash midway through a run is safe: the
 * next run simply deletes whatever remains. Work is chunked so a large backlog
 * does not hold a single long transaction or load every row into memory.
 */
export async function pruneExpiredSessions(now: Date = new Date()): Promise<number> {
  const where = {
    OR: [
      { expiresAt: { lt: now } },
      { revokedAt: { not: null, lt: revokedSessionCutoff(now) } },
    ],
  };

  let deleted = 0;
  for (;;) {
    const batch = await prisma.authSession.findMany({
      where,
      select: { id: true },
      orderBy: { id: 'asc' },
      take: SESSION_PRUNE_BATCH_SIZE,
    });
    if (batch.length === 0) break;

    const result = await prisma.authSession.deleteMany({
      where: { id: { in: batch.map((session) => session.id) } },
    });
    deleted += result.count;

    if (batch.length < SESSION_PRUNE_BATCH_SIZE) break;
    // Small pause between batches to avoid saturating the database.
    await delay(BATCH_PAUSE_MS);
  }
  return deleted;
}
