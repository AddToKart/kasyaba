import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { registerSchema, loginSchema, googleAuthSchema, refreshSchema } from './validation';
import * as authService from './service';
import { sendSuccess, sendCreated, sendNoContent } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {
  // POST /api/v1/auth/register
  app.post(
    '/api/v1/auth/register',
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
