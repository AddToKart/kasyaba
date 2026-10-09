import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pinoHttp from 'pino-http';
import rateLimit from 'express-rate-limit';
import { requestIdMiddleware } from './middleware/requestId';
import { errorHandler } from './middleware/errorHandler';
import { notFoundHandler } from './middleware/notFound';
import { env } from './config/env';
import { logger } from './lib/logger';
import { invalidateUserCaches } from './lib/user-cache';
import routes from './routes';

export { logger };

export function createApp() {
  const app = express();

  // Required for correct client IPs behind reverse proxies (Coolify/Dokploy,
  // nginx, PaaS ingress). Without it, express-rate-limit buckets every user
  // under the proxy address, so in production the value must be explicit:
  // "1" behind a single proxy, "false" only when the API is directly exposed.
  const trustProxyValue = env.TRUST_PROXY?.trim();
  if (env.NODE_ENV === 'production' && !trustProxyValue) {
    throw new Error(
      'TRUST_PROXY must be set explicitly in production ("1" behind a reverse proxy, "false" when directly exposed).',
    );
  }
  const trustProxy = parseTrustProxy(trustProxyValue);

  app.set('trust proxy', trustProxy);

  // Security
  app.use(helmet());

  // CORS is an API-only concern: the worker never serves HTTP requests and
  // must be able to boot without CORS configuration. Enforced here (not in the
  // shared env validation) so deployments fail fast on the API only.
  const allowedOrigins =
    env.NODE_ENV === 'production'
      ? env.CORS_ALLOWED_ORIGINS.split(',')
          .map((s) => s.trim())
          .filter(Boolean)
      : ['*'];
  if (
    env.NODE_ENV === 'production' &&
    (allowedOrigins.length === 0 || allowedOrigins.includes('*'))
  ) {
    throw new Error(
      'CORS_ALLOWED_ORIGINS must contain explicit origins in production.',
    );
  }
  app.use(cors({ origin: allowedOrigins }));

  // Body parsing
  app.use(express.json({ limit: '1mb' }));

  // Request ID
  app.use(requestIdMiddleware);

  // HTTP request logging. The URL serializer strips query strings so search
  // terms and other sensitive parameters never reach the logs.
  app.use(
    pinoHttp({
      logger,
      autoLogging: {
        ignore: (req) => (req.url ?? '').startsWith('/health'),
      },
      serializers: {
        req: (req) => ({
          method: req.method,
          url: (req.url ?? '').split('?')[0],
          remoteAddress: req.remoteAddress,
        }),
      },
    }),
  );

  // Health checks get a separate, generous limiter so they cannot be used to
  // hammer the database-backed readiness probe.
  app.use(
    '/health',
    rateLimit({
      windowMs: 60 * 1000,
      limit: 120,
      standardHeaders: 'draft-7',
      legacyHeaders: false,
    }),
  );

  app.use(
    '/api/v1',
    rateLimit({
      windowMs: 15 * 60 * 1000,
      limit: 300,
      standardHeaders: 'draft-7',
      legacyHeaders: false,
    }),
  );

  // Any successful mutating request clears the caller's derived-data caches so
  // a write cannot be followed by a stale dashboard/alerts read on this
  // instance. Cross-instance staleness is bounded by the short cache TTLs.
  app.use('/api/v1', (req, res, next) => {
    res.on('finish', () => {
      if (req.method !== 'GET' && req.userId && res.statusCode < 400) {
        invalidateUserCaches(req.userId);
      }
    });
    next();
  });

  // API routes
  app.use(routes);

  // Error handling
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}

function parseTrustProxy(value: string | undefined): boolean | number | string {
  if (value === undefined) return false;
  const normalized = value.trim().toLowerCase();
  if (normalized === '' || normalized === 'false' || normalized === '0') {
    return false;
  }
  if (normalized === 'true') return true;
  const hops = Number(normalized);
  if (Number.isInteger(hops) && hops >= 0) return hops;
  return value;
}
