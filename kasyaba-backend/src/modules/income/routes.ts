import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createIncomeSchema, updateIncomeSchema, incomeQuerySchema } from './validation';
import * as incomeService from './service';
import { sendSuccess, sendCreated, sendNoContent } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {
  app.get('/api/v1/income', authenticate, validate(incomeQuerySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await incomeService.listIncome(req.userId!, req.query as any);
      sendSuccess(res, result.data, result.meta);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/income', authenticate, validate(createIncomeSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await incomeService.createIncome(req.userId!, req.body);
      sendCreated(res, entry);
    } catch (err) { next(err); }
  });

  app.get('/api/v1/income/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await incomeService.getIncome(req.userId!, req.params.id);
      sendSuccess(res, entry);
    } catch (err) { next(err); }
  });

  app.patch('/api/v1/income/:id', authenticate, validate(updateIncomeSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await incomeService.updateIncome(req.userId!, req.params.id, req.body);
      sendSuccess(res, entry);
    } catch (err) { next(err); }
  });

  app.delete('/api/v1/income/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await incomeService.deleteIncome(req.userId!, req.params.id);
      sendNoContent(res);
    } catch (err) { next(err); }
  });
}
