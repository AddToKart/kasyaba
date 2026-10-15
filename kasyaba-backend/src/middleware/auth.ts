import { Request, Response, NextFunction } from 'express';
import { jwtVerify, SignJWT } from 'jose';
import { env } from '../config/env';
import { UnauthorizedError } from '../lib/errors';

const secret = new TextEncoder().encode(env.JWT_ACCESS_SECRET);

export interface TokenPayload {
  sub: string;
  email: string;
}

export async function signAccessToken(payload: TokenPayload): Promise<string> {
  return new SignJWT({ sub: payload.sub, email: payload.email })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime(`${env.ACCESS_TOKEN_TTL_MINUTES}m`)
    .sign(secret);
}

export async function verifyAccessToken(token: string): Promise<TokenPayload> {
  try {
    const { payload } = await jwtVerify(token, secret);
    if (typeof payload.sub !== 'string' || typeof payload.email !== 'string') {
      throw new Error('Token payload is incomplete');
    }
    return { sub: payload.sub, email: payload.email };
  } catch {
    throw new UnauthorizedError('Invalid or expired token');
  }
}

export async function authenticate(req: Request, _res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    const tokenMatch = authHeader?.match(/^Bearer\s+(\S+)$/i);
    if (!tokenMatch) {
      throw new UnauthorizedError('Missing or invalid authorization header');
    }
    const token = tokenMatch[1];
    const payload = await verifyAccessToken(token);
    req.userId = payload.sub;
    next();
  } catch (err) {
    next(err);
  }
}

export function optionalAuth(req: Request, _res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  const tokenMatch = authHeader?.match(/^Bearer\s+(\S+)$/i);
  if (!tokenMatch) {
    return next();
  }
  const token = tokenMatch[1];
  verifyAccessToken(token)
    .then((payload) => {
      req.userId = payload.sub;
      next();
    })
    .catch(() => next());
}
