import { PrismaClient } from '@prisma/client';

const rawUrl = process.env.DIRECT_URL || process.env.DATABASE_URL;

let dbUrl: string | undefined = rawUrl;
if (rawUrl) {
  try {
    const parsed = new URL(rawUrl);
    // Supabase free tier session pooler caps max connections at 15. Limit Prisma's
    // pool to 5 to prevent EMAXCONNSESSION and queuing delays.
    if (!parsed.searchParams.has('connection_limit')) {
      parsed.searchParams.set('connection_limit', '5');
    }
    dbUrl = parsed.toString();
  } catch {
    dbUrl = rawUrl;
  }
}

export const prisma = new PrismaClient({
  datasources: dbUrl ? { db: { url: dbUrl } } : undefined,
});
