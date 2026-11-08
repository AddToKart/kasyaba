import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

// No surplus mock: the tests drive the REAL calculateDailySurplus engine
// through mocked prisma aggregates, exercising the branch logic end-to-end.
vi.mock('../../config/database', () => ({
  prisma: {
    user: { findUnique: vi.fn() },
    incomeEntry: { aggregate: vi.fn() },
    expenseEntry: { aggregate: vi.fn() },
    savingsGoal: { findMany: vi.fn() },
  },
}));

import { prisma } from '../../config/database';
import * as goalService from './service';

const userId = 'user-1';

const mockedUser = vi.mocked(prisma.user.findUnique);
const mockedIncome = vi.mocked(prisma.incomeEntry.aggregate);
const mockedExpense = vi.mocked(prisma.expenseEntry.aggregate);
const mockedGoals = vi.mocked(prisma.savingsGoal.findMany);

function makeGoal() {
  return {
    id: 'goal-1',
    userId,
    name: 'Controller',
    targetAmount: 500,
    targetDate: new Date('2026-12-10T00:00:00.000Z'),
    status: 'active',
    createdAt: new Date('2026-11-01T00:00:00.000Z'),
    updatedAt: new Date('2026-11-01T00:00:00.000Z'),
    contributions: [] as { amount: string }[],
  };
}

function arrange(salary: string) {
  mockedGoals.mockResolvedValue([makeGoal()]);
  mockedUser.mockResolvedValue({ salaryAmount: salary });
  // Empty trailing cashflow: the surplus engine falls back to the salary-only
  // branch, which is exactly what a fresh account looks like.
  mockedIncome.mockResolvedValue({ _sum: { amount: null } });
  mockedExpense.mockResolvedValue({ _sum: { amount: null } });
}

describe('listGoals affordability basis', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    arrange('0'); // pick the common baseline; each test may override salary
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('leaves canAffordByTargetDate null when there is no surplus basis', async () => {
    // Salary 0 and no trailing cashflow -> daily surplus 0 -> no honest basis.
    const goals = await goalService.listGoals(userId);

    expect(goals).toHaveLength(1);
    expect(goals[0].canAffordByTargetDate).toBeNull();
    // The required pace itself is still stated exactly.
    expect(goals[0].monthlySavingsRequired).toBeTypeOf('number');
    expect(goals[0].monthlySavingsRequired).toBeGreaterThan(400);
  });

  it('computes canAffordByTargetDate when a surplus basis exists', async () => {
    // Salary 6000/month, no recorded expenses -> 200/day surplus -> covers 500.
    mockedUser.mockResolvedValue({ salaryAmount: '6000' });

    const goals = await goalService.listGoals(userId);

    expect(goals[0].canAffordByTargetDate).toBe(true);
  });

  it('flags goals that a real surplus cannot cover by the deadline', async () => {
    // Salary 30/month -> 1/day x 32 days = 32 < 500 -> cannot make it.
    mockedUser.mockResolvedValue({ salaryAmount: '30' });

    const goals = await goalService.listGoals(userId);

    expect(goals[0].canAffordByTargetDate).toBe(false);
  });
});
