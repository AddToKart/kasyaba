import { describe, expect, it } from 'vitest';
import { calculatePlanningOverview, buildPlanningEvents } from './service';

describe('calculatePlanningOverview', () => {
  it('calculates a transparent daily allowance from scheduled commitments', () => {
    const result = calculatePlanningOverview({
      from: '2026-08-29',
      to: '2026-08-31',
      currentBalance: '1000.00',
      minimumBalanceThreshold: '100.00',
      events: [
        { date: '2026-08-30', amount: '300.00', kind: 'income' },
        { date: '2026-08-31', amount: '200.00', kind: 'expense' },
        { date: '2026-08-31', amount: '100.00', kind: 'bill' },
      ],
    });

    expect(result.daysInWindow).toBe(3);
    expect(result.projectedClosingBalance).toBe('1000.00');
    expect(result.availableBuffer).toBe('900.00');
    expect(result.safeToSpendPerDay).toBe('300.00');
    expect(result.days[2]?.projectedBalance).toBe('1000.00');
  });

  it('never reports a positive allowance when the buffer is negative', () => {
    const result = calculatePlanningOverview({
      from: '2026-08-29',
      to: '2026-08-29',
      currentBalance: '100.00',
      minimumBalanceThreshold: '200.00',
      events: [],
    });

    expect(result.safeToSpendPerDay).toBe('0.00');
    expect(result.status).toBe('watch');
  });
});

describe('buildPlanningEvents (R1 regression tests)', () => {
  it('correctly clamps overdue bills to local today in Asia/Manila without dropping them', () => {
    // 2026-10-15 18:00:00 UTC = 2026-10-16 02:00:00 AM Asia/Manila (+08:00)
    const now = new Date('2026-10-15T18:00:00.000Z');
    const timeZone = 'Asia/Manila';
    const from = '2026-10-16';

    const overdueBill = {
      dueDate: new Date('2026-10-10T00:00:00.000Z'),
      amount: '500.00',
    };
    const sameDayBill = {
      dueDate: new Date('2026-10-15T20:00:00.000Z'), // 04:00 AM Manila on 2026-10-16
      amount: '300.00',
    };
    const futureBill = {
      dueDate: new Date('2026-10-20T00:00:00.000Z'),
      amount: '1200.00',
    };

    const events = buildPlanningEvents([], [], [overdueBill, sameDayBill, futureBill], now, timeZone, from);

    // Overdue bill must be clamped to local today ('2026-10-16'), not UTC yesterday ('2026-10-15')
    expect(events).toEqual([
      { date: '2026-10-16', amount: '500.00', kind: 'bill' },
      { date: '2026-10-16', amount: '300.00', kind: 'bill' },
      { date: '2026-10-20', amount: '1200.00', kind: 'bill' },
    ]);

    // When fed into calculatePlanningOverview, all three bills must be deducted and included
    const plan = calculatePlanningOverview({
      from: '2026-10-16',
      to: '2026-10-25',
      currentBalance: '5000.00',
      minimumBalanceThreshold: '1000.00',
      events,
    });

    expect(plan.totalUpcomingBills).toBe('2000.00'); // 500 + 300 + 1200
    expect(plan.projectedClosingBalance).toBe('3000.00'); // 5000 - 2000
    expect(plan.availableBuffer).toBe('2000.00'); // 3000 - 1000
    expect(plan.safeToSpendPerDay).toBe('200.00'); // 2000 / 10 days
  });

  it('clamps overdue bills to custom from window if from is in the future', () => {
    const now = new Date('2026-10-15T18:00:00.000Z');
    const timeZone = 'Asia/Manila';
    const from = '2026-10-20';

    const overdueBill = {
      dueDate: new Date('2026-10-10T00:00:00.000Z'),
      amount: '400.00',
    };

    const events = buildPlanningEvents([], [], [overdueBill], now, timeZone, from);
    expect(events[0]?.date).toBe('2026-10-20');
  });
});

