import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createCategorySchema, updateCategorySchema } from './validation';
import * as categoryService from './service';
import { sendSuccess, sendCreated } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {
  app.get('/api/v1/expense-categories', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const categories = await categoryService.listCategories(req.userId!);
      sendSuccess(res, categories);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/expense-categories', authenticate, validate(createCategorySchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const category = await categoryService.createCategory(req.userId!, req.body);
      sendCreated(res, category);
    } catch (err) { next(err); }
  });

  app.patch('/api/v1/expense-categories/:id', authenticate, validate(updateCategorySchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const category = await categoryService.updateCategory(req.userId!, req.params.id, req.body);
      sendSuccess(res, category);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/expense-categories/:id/archive', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const category = await categoryService.archiveCategory(req.userId!, req.params.id);
      sendSuccess(res, category);
    } catch (err) { next(err); }
  });
}
