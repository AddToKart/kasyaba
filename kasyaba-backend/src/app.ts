import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import pino from 'pino';
import pinoHttp from 'pino-http';
import { requestIdMiddleware } from './middleware/requestId';
import { errorHandler } from './middleware/errorHandler';
import { notFoundHandler } from './middleware/notFound';
import { env } from './config/env';
import routes from './routes';

export const logger = pino({
  level: env.LOG_LEVEL,
  transport: env.NODE_ENV === 'development' ? { target: 'pino-pretty' } : undefined,
  redact: ['req.headers.authorization', 'req.headers.cookie'],
});

export function createApp() {
  const app = express();

  // Security
  app.use(helmet());

  const allowedOrigins = env.NODE_ENV === 'production'
    ? env.CORS_ALLOWED_ORIGINS.split(',').map(s => s.trim()).filter(Boolean)
    : '*';
  app.use(cors({ origin: allowedOrigins }));

  // Body parsing
  app.use(express.json({ limit: '1mb' }));

  // Request ID
  app.use(requestIdMiddleware);

  // HTTP request logging
  app.use(pinoHttp({
    logger,
    autoLogging: {
      ignore: (req) => (req.url ?? '').startsWith('/health'),
    },
  }));

  // API routes
  app.use(routes);

  // Error handling
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
