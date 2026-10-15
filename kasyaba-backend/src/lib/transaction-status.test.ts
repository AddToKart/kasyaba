import { describe, expect, it } from 'vitest';
import { inferTransactionStatus } from './transaction-status';

describe('transaction status', () => {
  it('keeps an explicitly selected status', () => {
    expect(inferTransactionStatus(new Date('2099-01-01T00:00:00Z'), 'posted')).toBe('posted');
    expect(inferTransactionStatus(new Date('2000-01-01T00:00:00Z'), 'cancelled')).toBe('cancelled');
  });

  it('plans a future entry when no status is supplied', () => {
    expect(inferTransactionStatus(new Date(Date.now() + 86400000), undefined)).toBe('planned');
  });

  it('posts a past entry when no status is supplied', () => {
    expect(inferTransactionStatus(new Date(Date.now() - 86400000), undefined)).toBe('posted');
  });
});
