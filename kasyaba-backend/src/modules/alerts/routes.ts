import { authenticate } from '../../middleware/auth';
import * as alertService from './service';
import { sendSuccess, sendNoContent } from '../../lib/response';
import type { Router } from 'express';
import { Request, Response, NextFunction } from 'express';
export function registerRoutes(app: Router) {
  app.get('/api/v1/alerts', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const alerts = await alertService.listAlerts(req.userId!, req.query);
      sendSuccess(res, alerts);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/alerts/:id/read', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const alert = await alertService.markAlertRead(req.userId!, req.params.id);
      sendSuccess(res, alert);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/alerts/:id/dismiss', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const alert = await alertService.dismissAlert(req.userId!, req.params.id);
      sendSuccess(res, alert);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/alerts/read-all', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await alertService.readAllAlerts(req.userId!);
      sendNoContent(res);
    } catch (err) { next(err); }
  });
}
