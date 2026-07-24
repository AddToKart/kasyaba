import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createBudgetSchema, updateBudgetSchema, budgetStatusSchema } from './validation';
import * as budgetService from './service';
import { sendSuccess, sendCreated, sendNoContent } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {
  const router = app as any;

  router.get('/api/v1/budgets', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const budgets = await budgetService.listBudgets(req.userId!);
      sendSuccess(res, budgets);
    } catch (err) { next(err); }
  });

  router.post('/api/v1/budgets', authenticate, validate(createBudgetSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const budget = await budgetService.createBudget(req.userId!, req.body);
      sendCreated(res, budget);
    } catch (err) { next(err); }
  });

  router.patch('/api/v1/budgets/:id', authenticate, validate(updateBudgetSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const budget = await budgetService.updateBudget(req.userId!, req.params.id, req.body);
      sendSuccess(res, budget);
    } catch (err) { next(err); }
  });

  router.delete('/api/v1/budgets/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await budgetService.deleteBudget(req.userId!, req.params.id);
      sendNoContent(res);
    } catch (err) { next(err); }
  });

  router.get('/api/v1/budgets/status', authenticate, validate(budgetStatusSchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const status = await budgetService.getBudgetStatus(req.userId!, (req.query as any).month);
      sendSuccess(res, status);
    } catch (err) { next(err); }
  });
}
