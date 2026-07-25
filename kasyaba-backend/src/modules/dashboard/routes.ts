import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import * as dashboardService from './service';
import { sendSuccess } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {
  app.get('/api/v1/dashboard', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const period = (req.query.period as string) || 'month';
      const dashboard = await dashboardService.getDashboard(req.userId!, period);
      sendSuccess(res, dashboard);
    } catch (err) { next(err); }
  });
}
