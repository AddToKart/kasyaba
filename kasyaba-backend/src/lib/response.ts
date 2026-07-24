import { Response } from 'express';

interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
}

export function sendSuccess<T>(res: Response, data: T, meta?: PaginationMeta, statusCode = 200) {
  const body: Record<string, unknown> = { data };
  if (meta) body.meta = meta;
  return res.status(statusCode).json(body);
}

export function sendCreated<T>(res: Response, data: T) {
  return sendSuccess(res, data, undefined, 201);
}

export function sendNoContent(res: Response) {
  return res.status(204).send();
}
