import pino from 'pino';
import { env } from '../config/env';

/**
 * Shared structured logger. Request logs are emitted by pino-http with a
 * serializer that strips query strings; the redact list keeps credentials out
 * of any accidental nested logs.
 */
export const logger = pino({
  level: env.LOG_LEVEL,
  transport:
    env.NODE_ENV === 'development' ? { target: 'pino-pretty' } : undefined,
  redact: [
    'req.headers.authorization',
    'req.headers.cookie',
    'req.headers["set-cookie"]',
  ],
});
