import type { Request, Response, NextFunction } from 'express';
import type { Router } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { sendSuccess } from '../../lib/response';
import { planningQuerySchema } from './validation';
import * as planningService from './service';

export function registerRoutes(router: Router) {
  router.get('/api/v1/planning/overview', authenticate, validate(planningQuerySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const result = await planningService.getPlanningOverview(req.userId!, req.query);
      sendSuccess(res, result);
    } catch (error) {
      next(error);
    }
  });
}
