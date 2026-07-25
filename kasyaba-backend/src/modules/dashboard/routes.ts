import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import * as dashboardService from './service';
import { evaluatePurchaseAffordability } from '../forecasting/purchase-check';
import { sendSuccess } from '../../lib/response';

function doubleParse(val: any): number {
  if (typeof val === 'number') return val;
  return parseFloat(val) || 0;
}

export function registerRoutes(app: import('express').Router) {
  app.get('/api/v1/dashboard', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const period = (req.query.period as string) || 'month';
      const dashboard = await dashboardService.getDashboard(req.userId!, period);
      sendSuccess(res, dashboard);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/forecasting/purchase-check', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { itemTitle, amount } = req.body;
      const result = await evaluatePurchaseAffordability(req.userId!, {
        itemTitle: itemTitle || 'Intended Purchase',
        amount: doubleParse(amount),
      });
      sendSuccess(res, result);
    } catch (err) { next(err); }
  });
}
