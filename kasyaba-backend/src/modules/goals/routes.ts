import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createGoalSchema, updateGoalSchema, createContributionSchema } from './validation';
import * as goalService from './service';
import { sendSuccess, sendCreated, sendNoContent } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {
  const router = app as any;

  router.get('/api/v1/goals', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const goals = await goalService.listGoals(req.userId!);
      sendSuccess(res, goals);
    } catch (err) { next(err); }
  });

  router.post('/api/v1/goals', authenticate, validate(createGoalSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const goal = await goalService.createGoal(req.userId!, req.body);
      sendCreated(res, goal);
    } catch (err) { next(err); }
  });

  router.get('/api/v1/goals/:id', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const goal = await goalService.getGoal(req.userId!, req.params.id);
      sendSuccess(res, goal);
    } catch (err) { next(err); }
  });

  router.patch('/api/v1/goals/:id', authenticate, validate(updateGoalSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const goal = await goalService.updateGoal(req.userId!, req.params.id, req.body);
      sendSuccess(res, goal);
    } catch (err) { next(err); }
  });

  router.post('/api/v1/goals/:id/contributions', authenticate, validate(createContributionSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const contrib = await goalService.addContribution(req.userId!, req.params.id, req.body);
      sendCreated(res, contrib);
    } catch (err) { next(err); }
  });

  router.delete('/api/v1/goals/:id/contributions/:contributionId', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      await goalService.deleteContribution(req.userId!, req.params.id, req.params.contributionId);
      sendNoContent(res);
    } catch (err) { next(err); }
  });

  router.get('/api/v1/goals/:id/progress', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const progress = await goalService.getProgress(req.userId!, req.params.id);
      sendSuccess(res, progress);
    } catch (err) { next(err); }
  });
}
