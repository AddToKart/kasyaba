import { Request, Response, NextFunction } from 'express';
import { authenticate } from '../../middleware/auth';
import { validate } from '../../middleware/validate';
import { createBillTemplateSchema, updateBillTemplateSchema, billQuerySchema, markPaidSchema } from './validation';
import * as billService from './service';
import { sendSuccess, sendCreated } from '../../lib/response';

export function registerRoutes(app: import('express').Router) {

  // Bill Templates
  app.get('/api/v1/bill-templates', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const templates = await billService.listBillTemplates(req.userId!);
      sendSuccess(res, templates);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/bill-templates', authenticate, validate(createBillTemplateSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const template = await billService.createBillTemplate(req.userId!, req.body);
      sendCreated(res, template);
    } catch (err) { next(err); }
  });
  app.patch('/api/v1/bill-templates/:id', authenticate, validate(updateBillTemplateSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const template = await billService.updateBillTemplate(req.userId!, req.params.id, req.body);
      sendSuccess(res, template);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/bill-templates/:id/archive', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const template = await billService.archiveBillTemplate(req.userId!, req.params.id);
      sendSuccess(res, template);
    } catch (err) { next(err); }
  });

  app.get('/api/v1/bills', authenticate, validate(billQuerySchema, 'query'), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { rows, page, limit, total } = await billService.listBills(req.userId!, req.query);
      sendSuccess(res, rows, { page, limit, total });
    } catch (err) { next(err); }
  });

  app.post('/api/v1/bills/:id/mark-paid', authenticate, validate(markPaidSchema), async (req: Request, res: Response, next: NextFunction) => {
    try {
      const bill = await billService.markBillPaid(req.userId!, req.params.id, req.body.accountId);
      sendSuccess(res, bill);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/bills/:id/mark-unpaid', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const bill = await billService.markBillUnpaid(req.userId!, req.params.id);
      sendSuccess(res, bill);
    } catch (err) { next(err); }
  });

  app.post('/api/v1/bills/:id/cancel', authenticate, async (req: Request, res: Response, next: NextFunction) => {
    try {
      const bill = await billService.cancelBill(req.userId!, req.params.id);
      sendSuccess(res, bill);
    } catch (err) { next(err); }
  });
}
