import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../../config/database', () => ({
  prisma: {
    user: { findUnique: vi.fn() },
    financialSnapshot: { findFirst: vi.fn(), upsert: vi.fn() },
    budget: { findMany: vi.fn() },
    expenseEntry: { groupBy: vi.fn() },
    savingsGoal: { findMany: vi.fn() },
    savingsContribution: { groupBy: vi.fn() },
    billInstance: { findMany: vi.fn() },
  },
}));

vi.mock('../alerts/service', () => ({
  createAlert: vi.fn(),
  resolveAlertsByKey: vi.fn(),
}));

import { prisma } from '../../config/database';
import * as alertService from '../alerts/service';
import { generateAlertsFromSnapshot } from './service';

const userId = 'user-1';

beforeEach(() => {
  vi.clearAllMocks();
  vi.useFakeTimers();
  vi.setSystemTime(new Date('2026-11-06T10:00:00.000Z'));

  vi.mocked(prisma.user.findUnique).mockResolvedValue({
    id: userId,
    timezone: 'UTC',
    minimumBalanceThreshold: '0',
  } as never);
  vi.mocked(prisma.financialSnapshot.findFirst).mockResolvedValue({
    id: 'snapshot-1',
    predictedMonthEndBalance: '1000.00',
    expensesMonthToDate: '0.00',
    incomeMonthToDate: '0.00',
    actualBalance: '0.00',
    healthGrade: 'Good',
  } as never);
  vi.mocked(prisma.budget.findMany).mockResolvedValue([] as never);
  vi.mocked(prisma.expenseEntry.groupBy).mockResolvedValue([] as never);
  vi.mocked(prisma.savingsGoal.findMany).mockResolvedValue([] as never);
  vi.mocked(prisma.savingsContribution.groupBy).mockResolvedValue([] as never);
});

afterEach(() => {
  vi.useRealTimers();
});

describe('generateAlertsFromSnapshot bill due window', () => {
  it('includes a bill due today after 00:00 UTC', async () => {
    const dueToday = {
      id: 'bill-1',
      userId,
      templateId: null,
      name: 'Internet',
      amount: '1500.00',
      dueDate: new Date('2026-11-06T00:00:00.000Z'),
      status: 'upcoming',
      paidAt: null,
      expenseEntryId: null,
      createdAt: new Date('2026-11-01T00:00:00.000Z'),
      updatedAt: new Date('2026-11-01T00:00:00.000Z'),
    };

    // Apply the service's own due-date window to the fixture so the test fails
    // if the query still starts at the current instant.
    vi.mocked(prisma.billInstance.findMany).mockImplementation(async (args: any) => {
      const where = args?.where ?? {};
      let rows = [dueToday];
      if (where.status) {
        rows = rows.filter((bill) => bill.status === where.status);
      }
      if (where.dueDate?.gte) {
        rows = rows.filter((bill) => bill.dueDate >= where.dueDate.gte);
      }
      if (where.dueDate?.lte) {
        rows = rows.filter((bill) => bill.dueDate <= where.dueDate.lte);
      }
      return rows as never;
    });

    await generateAlertsFromSnapshot(userId);

    expect(prisma.billInstance.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: 'upcoming',
          dueDate: expect.objectContaining({
            gte: new Date('2026-11-06T00:00:00.000Z'),
          }),
        }),
      }),
    );
    expect(alertService.createAlert).toHaveBeenCalledWith(
      expect.objectContaining({
        type: 'bill_due',
        reasonData: expect.objectContaining({
          billName: 'Internet',
          daysUntilDue: 0,
        }),
      }),
    );
  });
});
