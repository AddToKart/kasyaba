import { Request, Response, NextFunction } from 'express';
import { AppError } from '../lib/errors';
import { env } from '../config/env';
import { logger } from '../lib/logger';
import { Prisma } from '@prisma/client';

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof AppError) {
    const body: Record<string, unknown> = {
      error: {
        code: err.code,
        message: err.message,
        requestId: req.requestId,
      },
    };
    if (err.fields) {
      (body.error as Record<string, unknown>).fields = err.fields;
    }
    return res.status(err.statusCode).json(body);
  }

  if (err instanceof Prisma.PrismaClientKnownRequestError) {
    const knownError = err.code === 'P2002'
      ? { statusCode: 409, code: 'CONFLICT', message: 'The resource already exists.' }
      : err.code === 'P2025'
        ? { statusCode: 404, code: 'NOT_FOUND', message: 'The requested resource was not found.' }
        : err.code === 'P2003'
          ? { statusCode: 400, code: 'INVALID_REFERENCE', message: 'The request references an invalid resource.' }
          : { statusCode: 500, code: 'INTERNAL_ERROR', message: 'An unexpected error occurred.' };

    return res.status(knownError.statusCode).json({
      error: {
        code: knownError.code,
        message: knownError.message,
        requestId: req.requestId,
      },
    });
  }

  // Structured logging keeps request context while pino redaction and the
  // request serializer keep credentials and query strings out of the logs.
  logger.error(
    {
      err,
      requestId: req.requestId,
      method: req.method,
      path: req.originalUrl.split('?')[0],
    },
    'Unhandled error',
  );

  return res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: env.NODE_ENV === 'production' ? 'An unexpected error occurred' : err.message,
      requestId: req.requestId,
    },
  });
}
