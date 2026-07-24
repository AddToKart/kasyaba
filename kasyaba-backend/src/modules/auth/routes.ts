import { Request, Response, NextFunction } from 'express';
import rateLimit from 'express-rate-limit';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { registerSchema, loginSchema, googleAuthSchema, refreshSchema } from './validation';
import * as authService from './service';
import { sendSuccess, sendCreated, sendNoContent } from '../../lib/response';

// Rate limiters for auth endpoints
const loginLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many login attempts. Try again later.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

const registerLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 3,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many registration attempts. Try again later.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

const refreshLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many refresh attempts. Try again later.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

const googleAuthLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: { error: { code: 'RATE_LIMITED', message: 'Too many authentication attempts. Try again later.' } },
  standardHeaders: true,
  legacyHeaders: false,
});

export function registerRoutes(app: import('express').Router) {
  // POST /api/v1/auth/register
  app.post(
    '/api/v1/auth/register',
    registerLimiter,
    validate(registerSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.registerUser(req.body);
        sendCreated(res, result);
      } catch (err) {
        next(err);
      }
    }
  );

  // POST /api/v1/auth/login
  app.post(
    '/api/v1/auth/login',
    loginLimiter,
    validate(loginSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.loginUser(req.body);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    }
  );

  // POST /api/v1/auth/google
  app.post(
    '/api/v1/auth/google',
    googleAuthLimiter,
    validate(googleAuthSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.googleAuth(req.body.idToken);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    }
  );

  // POST /api/v1/auth/refresh
  app.post(
    '/api/v1/auth/refresh',
    refreshLimiter,
    validate(refreshSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.refreshSession(req.body.refreshToken);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    }
  );

  // POST /api/v1/auth/logout
  app.post(
    '/api/v1/auth/logout',
    validate(refreshSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        await authService.logoutUser(req.body.refreshToken);
        sendNoContent(res);
      } catch (err) {
        next(err);
      }
    }
  );

  // POST /api/v1/auth/logout-all
  app.post(
    '/api/v1/auth/logout-all',
    authenticate,
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        await authService.logoutAllSessions(req.userId!);
        sendNoContent(res);
      } catch (err) {
        next(err);
      }
    }
  );

  // GET /api/v1/auth/me
  app.get(
    '/api/v1/auth/me',
    authenticate,
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const user = await authService.getCurrentUser(req.userId!);
        sendSuccess(res, user);
      } catch (err) {
        next(err);
      }
    }
  );
}
