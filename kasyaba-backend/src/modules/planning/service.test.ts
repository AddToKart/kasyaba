import { describe, expect, it } from 'vitest';
import { calculatePlanningOverview } from './service';

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
