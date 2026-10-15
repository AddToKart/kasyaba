import { describe, expect, it } from 'vitest';
import {
  isValidTransactionDate,
  parseDateOnlyEnd,
  parseDateOnlyStart,
  parseTransactionDate,
} from './transaction-dates';

describe('transaction dates', () => {
  it('accepts historical and future date-only values', () => {
    expect(isValidTransactionDate('2020-02-29')).toBe(true);
    expect(isValidTransactionDate('2099-12-31')).toBe(true);
  });

  it('rejects impossible calendar dates and trailing input', () => {
    expect(isValidTransactionDate('2024-02-30')).toBe(false);
    expect(isValidTransactionDate('2024-01-15-not-a-date')).toBe(false);
  });

  it('keeps date-only values on the selected calendar day', () => {
    const parsed = parseTransactionDate('2099-12-31');
    expect(parsed.toISOString()).toBe('2099-12-31T00:00:00.000Z');
  });

  it('builds inclusive UTC query boundaries', () => {
    expect(parseDateOnlyStart('2026-08-28').toISOString()).toBe(
      '2026-08-28T00:00:00.000Z',
    );
    expect(parseDateOnlyEnd('2026-08-28').toISOString()).toBe(
      '2026-08-28T23:59:59.999Z',
    );
  });
});
