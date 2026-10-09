import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import * as dashboardService from './service';
import { evaluatePurchaseAffordability } from '../forecasting/purchase-check';
import { sendSuccess } from '../../lib/response';
import { validate } from '../../middleware/validate';
import { z } from 'zod';

const dashboardQuerySchema = z.object({
  period: z.enum(['month']).default('month'),
});

const purchaseAmountSchema = z.union([
  z.number().finite().positive().max(1_000_000_000),
  z.string().regex(/^(?:0|[1-9]\d{0,11})(?:\.\d{1,2})?$/).transform(Number),
]).refine((amount) => Number.isFinite(amount) && amount <= 1_000_000_000, {
  message: 'Amount must be a finite value no greater than 1,000,000,000.',
});

const purchaseCheckSchema = z.object({
  itemTitle: z.string().trim().min(1).max(200),
  amount: purchaseAmountSchema,
}).refine((input) => input.amount > 0, {
  path: ['amount'],
  message: 'Amount must be greater than zero',
});

export function registerRoutes(app: import('express').Router) {
  app.get('/api/v1/dashboard', authenticate, validate(dashboardQuerySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const period = (req.query.period as string) || 'month';
      const dashboard = await dashboardService.getDashboard(req.userId!, period);
      sendSuccess(res, dashboard);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/forecasting/purchase-check', authenticate, validate(purchaseCheckSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { itemTitle, amount } = req.body;
      const result = await evaluatePurchaseAffordability(req.userId!, {
        itemTitle,
        amount,
      });
      sendSuccess(res, result);
    } catch (err) { next(err); }
  });
}
