import { describe, it, expect, vi, beforeEach } from 'vitest';
import { prisma } from '../../config/database';
import {
  pruneExpiredSessions,
  revokedSessionCutoff,
  SESSION_PRUNE_BATCH_SIZE,
} from './session-prune';

vi.mock('../../config/database', () => ({
  prisma: {
    authSession: {
      findMany: vi.fn(),
      deleteMany: vi.fn(),
    },
  },
}));

const NOW = new Date('2026-11-06T12:00:00.000Z');

describe('session pruning', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('deletes expired and long-revoked sessions in one batch', async () => {
    vi.mocked(prisma.authSession.findMany).mockResolvedValueOnce([
      { id: 'session-expired' },
      { id: 'session-revoked' },
    ]);
    vi.mocked(prisma.authSession.deleteMany).mockResolvedValueOnce({ count: 2 });

    const deleted = await pruneExpiredSessions(NOW);

    expect(deleted).toBe(2);
    expect(prisma.authSession.findMany).toHaveBeenCalledWith({
      where: {
        OR: [
          { expiresAt: { lt: NOW } },
          { revokedAt: { not: null, lt: revokedSessionCutoff(NOW) } },
        ],
      },
      select: { id: true },
      orderBy: { id: 'asc' },
      take: SESSION_PRUNE_BATCH_SIZE,
    });
    expect(prisma.authSession.deleteMany).toHaveBeenCalledWith({
      where: { id: { in: ['session-expired', 'session-revoked'] } },
    });
  });

  it('keeps fetching while a full batch is returned', async () => {
    const fullBatch = Array.from({ length: SESSION_PRUNE_BATCH_SIZE }, (_, i) => ({
      id: `session-${i}`,
    }));
    vi.mocked(prisma.authSession.findMany)
      .mockResolvedValueOnce(fullBatch)
      .mockResolvedValueOnce([]);
    vi.mocked(prisma.authSession.deleteMany).mockResolvedValueOnce({
      count: SESSION_PRUNE_BATCH_SIZE,
    });

    const deleted = await pruneExpiredSessions(NOW);

    expect(deleted).toBe(SESSION_PRUNE_BATCH_SIZE);
    expect(prisma.authSession.findMany).toHaveBeenCalledTimes(2);
    expect(prisma.authSession.deleteMany).toHaveBeenCalledTimes(1);
  });

  it('is a no-op when nothing matches', async () => {
    vi.mocked(prisma.authSession.findMany).mockResolvedValueOnce([]);

    await expect(pruneExpiredSessions(NOW)).resolves.toBe(0);
    expect(prisma.authSession.deleteMany).not.toHaveBeenCalled();
  });

  it('propagates delete failures so the job run is marked failed', async () => {
    vi.mocked(prisma.authSession.findMany).mockResolvedValueOnce([
      { id: 'session-expired' },
    ]);
    vi.mocked(prisma.authSession.deleteMany).mockRejectedValueOnce(
      new Error('database unavailable'),
    );

    await expect(pruneExpiredSessions(NOW)).rejects.toThrow('database unavailable');
  });

  it('uses a 30-day revocation retention window', () => {
    expect(revokedSessionCutoff(NOW).toISOString()).toBe(
      '2026-10-07T12:00:00.000Z',
    );
  });
});
