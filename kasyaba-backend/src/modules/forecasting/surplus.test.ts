import { describe, it, expect, vi, beforeEach } from 'vitest';
import Decimal from 'decimal.js';
import { calculateDailySurplus } from './surplus';
import { prisma } from '../../config/database';

vi.mock('../../config/database', () => ({
  prisma: {
    user: {
      findUnique: vi.fn(),
    },
    incomeEntry: {
      aggregate: vi.fn(),
    },
    expenseEntry: {
      aggregate: vi.fn(),
    },
  },
}));

describe('calculateDailySurplus (F16, R7)', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('calculates daily surplus from configured salary and projected expenses', async () => {
    (prisma.incomeEntry.aggregate as any).mockResolvedValue({ _sum: { amount: null } });
    (prisma.expenseEntry.aggregate as any).mockResolvedValue({ _sum: { amount: null } });

    const result = await calculateDailySurplus('user-1', {
      salaryAmount: '60000.00',
      projectedMonthEndExpenses: '30000.00',
    });

    // (60000 - 30000) / 30 = 1000/day
    expect(result.toString()).toBe('1000');
    expect(prisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('fetches salary from prisma when not in context and blends with trailing expenses', async () => {
    (prisma.user.findUnique as any).mockResolvedValue({ salaryAmount: new Decimal('45000.00') });
    (prisma.incomeEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('45000.00') } });
    (prisma.expenseEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('15000.00') } });

    const result = await calculateDailySurplus('user-2');

    // (45000 - 15000) / 30 = 1000/day
    expect(result.toString()).toBe('1000');
    expect(prisma.user.findUnique).toHaveBeenCalledWith({
      where: { id: 'user-2' },
      select: { salaryAmount: true },
    });
  });

  it('falls back to trailing 30-day net cashflow when salary is not configured', async () => {
    (prisma.incomeEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('50000.00') } });
    (prisma.expenseEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('20000.00') } });

    const result = await calculateDailySurplus('user-3', {
      salaryAmount: '0',
    });

    // (50000 - 20000) / 30 = 1000/day
    expect(result.toString()).toBe('1000');
  });

  it('falls back to MTD cashflow when trailing 30-day has no net surplus', async () => {
    (prisma.incomeEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('10000.00') } });
    (prisma.expenseEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('15000.00') } }); // negative trailing net

    const result = await calculateDailySurplus('user-4', {
      salaryAmount: '0',
      incomeMTD: '40000.00',
      expensesMTD: '10000.00',
    });

    // (40000 - 10000) / 30 = 1000/day
    expect(result.toString()).toBe('1000');
  });

  it('returns 0 when all cashflow and salary sources are zero or negative', async () => {
    (prisma.incomeEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('5000.00') } });
    (prisma.expenseEntry.aggregate as any).mockResolvedValue({ _sum: { amount: new Decimal('8000.00') } });

    const result = await calculateDailySurplus('user-5', {
      salaryAmount: '0',
      incomeMTD: '5000.00',
      expensesMTD: '8000.00',
    });

    expect(result.toString()).toBe('0');
  });
});

