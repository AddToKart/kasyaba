import type { Router, Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { sendCreated, sendNoContent, sendSuccess } from '../../lib/response';
import { createTransferSchema, transactionQuerySchema } from './validation';
import * as transactionService from './service';

export function registerRoutes(router: Router) {
  router.get('/api/v1/transactions', authenticate, validate(transactionQuerySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await transactionService.listTransactions(req.userId!, req.query as never);
      sendSuccess(res, result.data, result.meta);
    } catch (error) {
      next(error);
    }
  });

  router.post('/api/v1/transfers', authenticate, validate(createTransferSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const transfer = await transactionService.createTransfer(req.userId!, req.body);
      sendCreated(res, transfer);
    } catch (error) {
      next(error);
    }
  });

  router.delete('/api/v1/transfers/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await transactionService.deleteTransfer(req.userId!, req.params.id);
      sendNoContent(res);
    } catch (error) {
      next(error);
    }
  });
}
