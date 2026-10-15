import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4, validate as isUuid } from 'uuid';

export function requestIdMiddleware(req: Request, res: Response, next: NextFunction) {
  const supplied = req.headers['x-request-id'];
  const requestId = typeof supplied === 'string' && supplied.length <= 100 && isUuid(supplied)
    ? supplied
    : uuidv4();
  req.requestId = requestId;
  res.setHeader('x-request-id', requestId);
  next();
}
