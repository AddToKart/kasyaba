import { prisma } from '../../config/database';
import { NotFoundError } from '../../lib/errors';
import { addMonths } from '../../lib/dates';
import type { CreateBillTemplateInput, UpdateBillTemplateInput } from './validation';

export async function listBillTemplates(userId: string) {
  return prisma.billTemplate.findMany({
    where: { userId, isActive: true },
    orderBy: { createdAt: 'desc' },
  });
}

export async function createBillTemplate(userId: string, input: CreateBillTemplateInput) {
  return prisma.billTemplate.create({
    data: {
      userId,
      name: input.name,
      defaultAmount: input.defaultAmount,
      categoryId: input.categoryId || null,
      recurrence: input.recurrence,
      dayOfWeek: input.dayOfWeek ?? null,
      dayOfMonth: input.dayOfMonth ?? null,
      startsOn: new Date(input.startsOn),
      endsOn: input.endsOn ? new Date(input.endsOn) : null,
      reminderLeadDays: input.reminderLeadDays,
      isActive: input.isActive,
    },
  });
}

export async function updateBillTemplate(userId: string, id: string, input: UpdateBillTemplateInput) {
  const existing = await prisma.billTemplate.findFirst({ where: { id, userId } });
  if (!existing) throw new NotFoundError('Bill template not found');

  const data: any = { ...input };
  if (input.startsOn) data.startsOn = new Date(input.startsOn);
  if (input.endsOn !== undefined) data.endsOn = input.endsOn ? new Date(input.endsOn) : null;
  if (input.dayOfWeek !== undefined) data.dayOfWeek = input.dayOfWeek ?? null;
  if (input.dayOfMonth !== undefined) data.dayOfMonth = input.dayOfMonth ?? null;

  return prisma.billTemplate.update({ where: { id }, data });
}

export async function archiveBillTemplate(userId: string, id: string) {
  const existing = await prisma.billTemplate.findFirst({ where: { id, userId } });
  if (!existing) throw new NotFoundError('Bill template not found');
  return prisma.billTemplate.update({
    where: { id },
    data: { isActive: false },
  });
}

export async function listBills(userId: string, query: Record<string, any>) {
  const where: any = { userId };

  if (query.status) where.status = query.status;
  if (query.from || query.to) {
    where.dueDate = {};
    if (query.from) where.dueDate.gte = new Date(query.from);
    if (query.to) where.dueDate.lte = new Date(query.to + 'T23:59:59.999Z');
  }

  return prisma.billInstance.findMany({
    where,
    orderBy: { dueDate: 'asc' },
  });
}

export async function markBillPaid(userId: string, billId: string, createExpense = false) {
  const bill = await prisma.billInstance.findFirst({ where: { id: billId, userId } });
  if (!bill) throw new NotFoundError('Bill not found');

  const updateData: any = {
    status: 'paid',
    paidAt: new Date(),
  };

  if (createExpense && bill.templateId) {
    const template = await prisma.billTemplate.findUnique({ where: { id: bill.templateId } });
    if (template && template.categoryId) {
      // Find a default account to create the expense against
      const account = await prisma.financialAccount.findFirst({
        where: { userId, isArchived: false },
      });

      if (account) {
        const expense = await prisma.expenseEntry.create({
          data: {
            userId,
            accountId: account.id,
            categoryId: template.categoryId,
            amount: bill.amount,
            description: `${bill.name} (paid bill)`,
            spentAt: new Date(),
          },
        });
        updateData.expenseEntryId = expense.id;
      }
    }
  }

  return prisma.billInstance.update({
    where: { id: billId },
    data: updateData,
  });
}

export async function markBillUnpaid(userId: string, billId: string) {
  const bill = await prisma.billInstance.findFirst({ where: { id: billId, userId } });
  if (!bill) throw new NotFoundError('Bill not found');

  // If there was an expense created, delete it
  if (bill.expenseEntryId) {
    const expense = await prisma.expenseEntry.findUnique({ where: { id: bill.expenseEntryId } });
    if (expense && expense.userId === userId) {
      await prisma.expenseEntry.delete({ where: { id: bill.expenseEntryId } });
    }
  }

  return prisma.billInstance.update({
    where: { id: billId },
    data: {
      status: 'upcoming',
      paidAt: null,
      expenseEntryId: null,
    },
  });
}

export async function cancelBill(userId: string, billId: string) {
  const bill = await prisma.billInstance.findFirst({ where: { id: billId, userId } });
  if (!bill) throw new NotFoundError('Bill not found');
  return prisma.billInstance.update({
    where: { id: billId },
    data: { status: 'cancelled' },
  });
}

export async function generateBillInstances(userId: string, monthsAhead = 2) {
  const templates = await prisma.billTemplate.findMany({
    where: { userId, isActive: true, recurrence: { not: 'none' } },
  });

  const now = new Date();
  const endDate = addMonths(now, monthsAhead);
  const created: number[] = [];

  for (const template of templates) {
    let currentDate = new Date(template.startsOn);
    if (currentDate < now) {
      // Move to next occurrence
      if (template.recurrence === 'monthly' && template.dayOfMonth) {
        currentDate = new Date(now.getFullYear(), now.getMonth(), template.dayOfMonth);
        if (currentDate < now) {
          currentDate = addMonths(currentDate, 1);
        }
      } else if (template.recurrence === 'weekly' && template.dayOfWeek !== null) {
        // Find next day of week
        const dayDiff = (template.dayOfWeek - currentDate.getDay() + 7) % 7;
        currentDate = new Date(now.getTime() + dayDiff * 86400000);
        if (currentDate < now) {
          currentDate = new Date(currentDate.getTime() + 7 * 86400000);
        }
      }
    }

    while (currentDate <= endDate) {
      if (template.endsOn && currentDate > template.endsOn) break;

      // Check if instance already exists
      const existing = await prisma.billInstance.findFirst({
        where: {
          templateId: template.id,
          dueDate: currentDate,
        },
      });

      if (!existing) {
        await prisma.billInstance.create({
          data: {
            userId,
            templateId: template.id,
            name: template.name,
            amount: template.defaultAmount,
            dueDate: currentDate,
          },
        });
        created.push(1);
      }

      // Advance date
      if (template.recurrence === 'monthly') {
        currentDate = addMonths(currentDate, 1);
      } else if (template.recurrence === 'weekly') {
        currentDate = new Date(currentDate.getTime() + 7 * 86400000);
      } else {
        break;
      }
    }
  }

  return created.length;
}

export async function updateOverdueBills(userId: string) {
  const now = new Date();
  const result = await prisma.billInstance.updateMany({
    where: {
      userId,
      status: 'upcoming',
      dueDate: { lt: now },
    },
    data: { status: 'overdue' },
  });
  return result.count;
}
