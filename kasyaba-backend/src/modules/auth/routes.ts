import type { Router } from "express";
import { Request, Response, NextFunction } from "express";
import rateLimit from "express-rate-limit";
import { authenticate } from "../../middleware/auth";
import { validate } from "../../middleware/validate";
import {
  registerSchema,
  loginSchema,
  googleAuthSchema,
  refreshSchema,
  updateProfileSchema,
  deleteAccountSchema,
  restoreSchema,
} from "./validation";
import * as authService from "./service";
import { sendSuccess, sendCreated, sendNoContent } from "../../lib/response";

// Rate limiters for auth endpoints
const loginLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5,
  skip: () => process.env.NODE_ENV === "test",
  message: {
    error: {
      code: "RATE_LIMITED",
      message: "Too many login attempts. Try again later.",
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const registerLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 3,
  skip: () => process.env.NODE_ENV === "test",
  message: {
    error: {
      code: "RATE_LIMITED",
      message: "Too many registration attempts. Try again later.",
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const refreshLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  skip: () => process.env.NODE_ENV === "test",
  message: {
    error: {
      code: "RATE_LIMITED",
      message: "Too many refresh attempts. Try again later.",
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

const googleAuthLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  skip: () => process.env.NODE_ENV === "test",
  message: {
    error: {
      code: "RATE_LIMITED",
      message: "Too many authentication attempts. Try again later.",
    },
  },
  standardHeaders: true,
  legacyHeaders: false,
});

export function registerRoutes(router: Router) {
  // POST /api/v1/auth/register
  router.post(
    "/api/v1/auth/register",
    registerLimiter,
    validate(registerSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.registerUser(req.body);
        sendCreated(res, result);
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /api/v1/auth/login
  router.post(
    "/api/v1/auth/login",
    loginLimiter,
    validate(loginSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.loginUser(req.body);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /api/v1/auth/google
  router.post(
    "/api/v1/auth/google",
    googleAuthLimiter,
    validate(googleAuthSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.googleAuth(req.body.idToken);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /api/v1/auth/refresh
  router.post(
    "/api/v1/auth/refresh",
    refreshLimiter,
    validate(refreshSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.refreshSession(req.body.refreshToken);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /api/v1/auth/logout
  router.post(
    "/api/v1/auth/logout",
    authenticate,
    validate(refreshSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        await authService.logoutUser(req.userId!, req.body.refreshToken);
        sendNoContent(res);
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /api/v1/auth/logout-all
  router.post(
    "/api/v1/auth/logout-all",
    authenticate,
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        await authService.logoutAllSessions(req.userId!);
        sendNoContent(res);
      } catch (err) {
        next(err);
      }
    },
  );

  // GET /api/v1/auth/me
  router.get(
    "/api/v1/auth/me",
    authenticate,
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const user = await authService.getCurrentUser(req.userId!);
        sendSuccess(res, user);
      } catch (err) {
        next(err);
      }
    },
  );

  // PATCH /api/v1/auth/me
  router.patch(
    "/api/v1/auth/me",
    authenticate,
    validate(updateProfileSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const updated = await authService.updateProfile(req.userId!, req.body);
        sendSuccess(res, updated);
      } catch (err) {
        next(err);
      }
    },
  );

  // DELETE /api/v1/auth/me (Google Play Mandated Account & Data Deletion)
  router.delete(
    "/api/v1/auth/me",
    authenticate,
    validate(deleteAccountSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        await authService.deleteAccount(req.userId!, req.body.password);
        sendNoContent(res);
      } catch (err) {
        next(err);
      }
    },
  );

  // GET /api/v1/auth/export (User Data Portability / Export)
  router.get(
    "/api/v1/auth/export",
    authenticate,
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const data = await authService.exportUserData(req.userId!);
        sendSuccess(res, data);
      } catch (err) {
        next(err);
      }
    },
  );

  // POST /api/v1/auth/restore (User Data Restore / Import)
  router.post(
    "/api/v1/auth/restore",
    authenticate,
    validate(restoreSchema),
    async (req: Request, res: Response, next: NextFunction) => {
      try {
        const result = await authService.restoreUserData(req.userId!, req.body);
        sendSuccess(res, result);
      } catch (err) {
        next(err);
      }
    },
  );
}
