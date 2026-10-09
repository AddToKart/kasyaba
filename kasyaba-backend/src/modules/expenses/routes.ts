import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createExpenseSchema, updateExpenseSchema, expenseQuerySchema, categorySummarySchema } from './validation';
import * as expenseService from './service';
import { sendSuccess, sendCreated, sendNoContent } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {

  app.get('/api/v1/expenses', authenticate, validate(expenseQuerySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await expenseService.listExpenses(req.userId!, req.query as any);
      sendSuccess(res, result.data, result.meta);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/expenses', authenticate, validate(createExpenseSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await expenseService.createExpense(req.userId!, req.body);
      sendCreated(res, entry);
    } catch (err) { next(err); }
  });

  // Keep this static path before /:id, otherwise Express treats "summary"
  // as an expense id and the summary endpoint is unreachable.
  app.get('/api/v1/expenses/summary/by-category', authenticate, validate(categorySummarySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { from, to } = req.query as any;
      const summary = await expenseService.getCategorySummary(req.userId!, from, to);
      sendSuccess(res, summary);
    } catch (err) { next(err); }
  });

  app.get('/api/v1/expenses/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await expenseService.getExpense(req.userId!, req.params.id);
      sendSuccess(res, entry);
    } catch (err) { next(err); }
  });

  app.patch('/api/v1/expenses/:id', authenticate, validate(updateExpenseSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const entry = await expenseService.updateExpense(req.userId!, req.params.id, req.body);
      sendSuccess(res, entry);
    } catch (err) { next(err); }
  });

  app.delete('/api/v1/expenses/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await expenseService.deleteExpense(req.userId!, req.params.id);
      sendNoContent(res);
    } catch (err) { next(err); }
  });

}
