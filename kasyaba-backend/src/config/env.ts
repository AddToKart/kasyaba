import 'dotenv/config';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
  PORT: z.coerce.number().int().positive().max(65535).default(3000),
  // Opt-in only: seeding the known demo credentials must never happen by
  // accident against a shared or production database.
  SEED_DEMO_USER: z
    .enum(['true', 'false'])
    .default('false')
    .transform((value) => value === 'true'),
  DATABASE_URL: z.string().min(1),
  DIRECT_URL: z.string().min(1),
  JWT_ACCESS_SECRET: z.string().min(32),
  ACCESS_TOKEN_TTL_MINUTES: z.coerce.number().positive().default(15),
  REFRESH_TOKEN_TTL_DAYS: z.coerce.number().positive().default(30),
  GOOGLE_WEB_CLIENT_ID: z.string().optional(),
  CORS_ALLOWED_ORIGINS: z.string().default('*'),
  // Number of trusted reverse-proxy hops ("1" behind a single proxy, "false"
  // when the API is exposed directly, or an IP/subnet list).
  TRUST_PROXY: z.string().default('false'),
  SUPPORT_EMAIL: z.string().email().default('support@kasyaba.app'),
  LOG_LEVEL: z.enum(['trace', 'debug', 'info', 'warn', 'error', 'fatal']).default('info'),
  WORKER_TIMEZONE: z.string().default('Asia/Manila'),
  SNAPSHOT_CRON: z.string().default('10 0 * * *'),
});

function validateEnv() {
  const result = envSchema.safeParse(process.env);
  if (!result.success) {
    console.error('Invalid environment variables:', result.error.flatten().fieldErrors);
    process.exit(1);
  }
  if (
    result.data.NODE_ENV === 'production' &&
    result.data.JWT_ACCESS_SECRET ===
      'dev-access-secret-at-least-32-characters-long'
  ) {
    console.error(
      'JWT_ACCESS_SECRET must not use the development default in production.',
    );
    process.exit(1);
  }
  return result.data;
}

export const env = validateEnv();
export type Env = z.infer<typeof envSchema>;
