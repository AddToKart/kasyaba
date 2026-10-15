import { prisma } from '../../config/database';
import { ConflictError, NotFoundError } from '../../lib/errors';
import { addMonths, safeDate } from '../../lib/dates';
import { endOfZonedDay } from '../../lib/zoned-dates';
import type { CreateBillTemplateInput, UpdateBillTemplateInput } from './validation';

export async function listBillTemplates(userId: string) {
  return prisma.billTemplate.findMany({
    where: { userId, isActive: true },
    orderBy: { createdAt: 'desc' },
  });
}

async function findAccessibleCategory(userId: string, categoryId?: string | null) {
  if (categoryId) {
    const category = await prisma.expenseCategory.findFirst({
      where: { id: categoryId, isArchived: false, OR: [{ userId }, { userId: null }] },
      select: { id: true },
    });
    if (!category) throw new NotFoundError('Category not found');
    return category.id;
  }

  const fallback = await prisma.expenseCategory.findFirst({
    where: { userId: null, name: 'Other', isArchived: false },
    select: { id: true },
  });
  if (!fallback) throw new NotFoundError('Default expense category not found');
  return fallback.id;
}

export async function createBillTemplate(userId: string, input: CreateBillTemplateInput) {
  if (input.categoryId) await findAccessibleCategory(userId, input.categoryId);
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
  if (input.categoryId !== undefined) {
    await findAccessibleCategory(userId, input.categoryId);
  }

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
  const page = Number(query.page) || 1;
  const limit = Math.min(Number(query.limit) || 200, 500);
  const where: any = { userId };

  if (query.status) where.status = query.status;
  if (query.from || query.to) {
    where.dueDate = {};
    if (query.from) where.dueDate.gte = new Date(query.from);
    if (query.to) where.dueDate.lte = new Date(query.to + 'T23:59:59.999Z');
  }

  // Bounded response: paid/overdue instances accumulate over the years.
  const [total, rows] = await Promise.all([
    prisma.billInstance.count({ where }),
    prisma.billInstance.findMany({
      where,
      orderBy: { dueDate: 'asc' },
      skip: (page - 1) * limit,
      take: limit,
    }),
  ]);

  return { rows, page, limit, total };
}

export async function markBillPaid(userId: string, billId: string, accountId: string) {
  return prisma.$transaction(async (tx) => {
    const account = await tx.financialAccount.findFirst({
      where: { id: accountId, userId, isArchived: false },
      select: { id: true },
    });
    if (!account) throw new NotFoundError('Account not found');

    const bill = await tx.billInstance.findFirst({ where: { id: billId, userId } });
    if (!bill) throw new NotFoundError('Bill not found');
    if (bill.status === 'paid') throw new ConflictError('Bill is already paid');
    if (bill.status === 'cancelled') throw new ConflictError('Cancelled bills cannot be paid');

    // The conditional update makes concurrent payment requests mutually
    // exclusive. A second request waits for the first transaction and then
    // observes that the bill is already paid.
    const claimed = await tx.billInstance.updateMany({
      where: { id: billId, userId, status: { notIn: ['paid', 'cancelled'] } },
      data: { status: 'paid', paidAt: new Date() },
    });
    if (claimed.count !== 1) throw new ConflictError('Bill is already paid');

    let categoryId: string | null = null;
    if (bill.templateId) {
      const template = await tx.billTemplate.findFirst({
        where: { id: bill.templateId, userId },
        select: { categoryId: true },
      });
      categoryId = template?.categoryId ?? null;
    }

    if (categoryId) {
      const category = await tx.expenseCategory.findFirst({
        where: { id: categoryId, isArchived: false, OR: [{ userId }, { userId: null }] },
        select: { id: true },
      });
      categoryId = category?.id ?? null;
    }
    categoryId ??= (await tx.expenseCategory.findFirst({
      where: { userId: null, name: 'Other', isArchived: false },
      select: { id: true },
    }))?.id ?? null;
    if (!categoryId) throw new NotFoundError('Default expense category not found');

    const expense = await tx.expenseEntry.create({
      data: {
        userId,
        accountId: account.id,
        categoryId,
        amount: bill.amount,
        description: `${bill.name} (paid bill)`,
        spentAt: new Date(),
      },
    });

    return tx.billInstance.update({
      where: { id: billId },
      data: { expenseEntryId: expense.id },
    });
  });
}

export async function markBillUnpaid(userId: string, billId: string) {
  return prisma.$transaction(async (tx) => {
    const bill = await tx.billInstance.findFirst({ where: { id: billId, userId } });
    if (!bill) throw new NotFoundError('Bill not found');
    if (bill.status !== 'paid') {
      throw new ConflictError('Only paid bills can be marked unpaid');
    }

    // Conditional claim keeps concurrent unpaid requests mutually exclusive.
    const claimed = await tx.billInstance.updateMany({
      where: { id: billId, userId, status: 'paid' },
      data: { status: 'upcoming', paidAt: null, expenseEntryId: null },
    });
    if (claimed.count !== 1) {
      throw new ConflictError('Bill state changed. Refresh and try again.');
    }

    if (bill.expenseEntryId) {
      await tx.expenseEntry.deleteMany({
        where: { id: bill.expenseEntryId, userId },
      });
    }

    return tx.billInstance.findUnique({ where: { id: billId } });
  });
}

export async function cancelBill(userId: string, billId: string) {
  // A bill that has already been paid must be marked unpaid first: otherwise
  // the linked expense would remain counted while the bill shows cancelled.
  const claimed = await prisma.billInstance.updateMany({
    where: { id: billId, userId, status: { notIn: ['paid', 'cancelled'] } },
    data: { status: 'cancelled' },
  });
  if (claimed.count === 0) {
    const bill = await prisma.billInstance.findFirst({
      where: { id: billId, userId },
    });
    if (!bill) throw new NotFoundError('Bill not found');
    if (bill.status === 'paid') {
      throw new ConflictError('Paid bills cannot be cancelled. Mark the bill unpaid first.');
    }
    throw new ConflictError('Bill is already cancelled');
  }
  return prisma.billInstance.findUnique({ where: { id: billId } });
}

export async function generateBillInstances(userId: string, monthsAhead = 2) {
  const templates = await prisma.billTemplate.findMany({
    where: { userId, isActive: true },
  });

  const now = new Date();
  const endDate = addMonths(now, monthsAhead);
  const created: number[] = [];

  for (const template of templates) {
    let currentDate = new Date(template.startsOn);
    if (currentDate < now) {
      // Move to next occurrence
      if (template.recurrence === 'monthly' && template.dayOfMonth) {
        currentDate = safeDate(now.getFullYear(), now.getMonth(), template.dayOfMonth);
        currentDate.setHours(
          template.startsOn.getHours(),
          template.startsOn.getMinutes(),
          template.startsOn.getSeconds(),
          template.startsOn.getMilliseconds(),
        );
        if (currentDate < now) {
          currentDate = addMonths(currentDate, 1);
        }
      } else if (template.recurrence === 'weekly' && template.dayOfWeek !== null) {
        // Find next day of week
        const dayDiff = (template.dayOfWeek - now.getDay() + 7) % 7;
        currentDate = new Date(now.getTime() + dayDiff * 86400000);
        currentDate.setHours(
          template.startsOn.getHours(),
          template.startsOn.getMinutes(),
          template.startsOn.getSeconds(),
          template.startsOn.getMilliseconds(),
        );
        if (currentDate < now) {
          currentDate = new Date(currentDate.getTime() + 7 * 86400000);
        }
      }
    }

    while (currentDate <= endDate) {
      if (template.endsOn && currentDate > template.endsOn) break;

      const existing = await prisma.billInstance.findUnique({
        where: {
          templateId_dueDate: {
            templateId: template.id,
            dueDate: currentDate,
          },
        },
        select: { id: true },
      });

      await prisma.billInstance.upsert({
        where: {
          templateId_dueDate: {
            templateId: template.id,
            dueDate: currentDate,
          },
        },
        create: {
          userId,
          templateId: template.id,
          name: template.name,
          amount: template.defaultAmount,
          dueDate: currentDate,
        },
        update: {},
      });

      if (!existing) created.push(1);

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
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { timezone: true },
  });
  const timeZone = user?.timezone ?? 'UTC';
  const now = new Date();

  // A bill is only overdue once its entire local due date has elapsed in the user's timezone.
  const candidates = await prisma.billInstance.findMany({
    where: {
      userId,
      status: 'upcoming',
      dueDate: { lte: now },
    },
    select: { id: true, dueDate: true },
  });

  const overdueIds = candidates
    .filter((bill) => endOfZonedDay(bill.dueDate, timeZone) < now)
    .map((bill) => bill.id);

  if (overdueIds.length === 0) return 0;

  const result = await prisma.billInstance.updateMany({
    where: {
      id: { in: overdueIds },
      status: 'upcoming',
    },
    data: { status: 'overdue' },
  });
  return result.count;
}
