import type { Router } from 'express';
import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createAccountSchema, updateAccountSchema } from './validation';
import * as accountService from './service';
import { sendSuccess, sendCreated } from '../../lib/response';

export function registerRoutes(router: Router) {

  // GET /api/v1/accounts
  router.get('/api/v1/accounts', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const accounts = await accountService.listAccounts(req.userId!);
      sendSuccess(res, accounts);
    } catch (err) { next(err); }
  });

  // POST /api/v1/accounts
  router.post('/api/v1/accounts', authenticate, validate(createAccountSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const account = await accountService.createAccount(req.userId!, req.body);
      sendCreated(res, account);
    } catch (err) { next(err); }
  });

  // PATCH /api/v1/accounts/:id
  router.patch('/api/v1/accounts/:id', authenticate, validate(updateAccountSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const account = await accountService.updateAccount(req.userId!, req.params.id, req.body);
      sendSuccess(res, account);
    } catch (err) { next(err); }
  });

  // POST /api/v1/accounts/:id/archive
  router.post('/api/v1/accounts/:id/archive', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const account = await accountService.archiveAccount(req.userId!, req.params.id);
      sendSuccess(res, account);
    } catch (err) { next(err); }
  });

  // GET /api/v1/accounts/:id/balance
  router.get('/api/v1/accounts/:id/balance', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const balance = await accountService.getAccountBalance(req.userId!, req.params.id);
      sendSuccess(res, balance);
    } catch (err) { next(err); }
  });
}
