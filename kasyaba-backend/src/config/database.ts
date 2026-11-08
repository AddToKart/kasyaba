import { PrismaClient } from '@prisma/client';

/**
 * Pool routing for Supabase (per Supabase's recommended layout):
 *
 * - Runtime traffic (the long-running API/worker clients) uses
 *   DATABASE_URL: the transaction-mode pooler (6543, `pgbouncer=true`).
 *   It is built for application traffic and tolerates the connection churn
 *   of a long-running server process.
 *
 * - DIRECT_URL (the session pooler / direct endpoint, 5432) stays reserved
 *   for migrations and managed jobs. It previously took precedence here,
 *   which routed all app traffic through the 15-client session pooler and
 *   caused EMAXCONNSESSION saturation when the API and worker ran together.
 */
const runtimeUrl = process.env.DATABASE_URL || process.env.DIRECT_URL;

function withPoolLimit(url: string | undefined, limit: string): string | undefined {
  if (!url) return url;
  try {
    const parsed = new URL(url);
    // Supabase's shared pooler caps concurrent clients (15). Keep the
    // Prisma pool well under it and fail fast with a bounded wait instead
    // of hanging when the cap is momentarily reached.
    if (!parsed.searchParams.has('connection_limit')) {
      parsed.searchParams.set('connection_limit', limit);
    }
    if (!parsed.searchParams.has('pool_timeout')) {
      parsed.searchParams.set('pool_timeout', '15');
    }
    return parsed.toString();
  } catch {
    return url;
  }
}

export const prisma = new PrismaClient({
  datasources: { db: { url: withPoolLimit(runtimeUrl, '4') ?? undefined } },
});
