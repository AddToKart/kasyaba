import { describe, expect, it } from 'vitest';
import { createTransferSchema, transactionQuerySchema } from './validation';

describe('transaction validation', () => {
  it('accepts planned transfers and transaction filters', () => {
    expect(createTransferSchema.safeParse({
      fromAccountId: '00000000-0000-0000-0000-000000000001',
      toAccountId: '00000000-0000-0000-0000-000000000002',
      amount: '100.00',
      transferredAt: '2099-12-31',
      status: 'planned',
    }).success).toBe(true);
    expect(transactionQuerySchema.safeParse({
      page: '2',
      limit: '50',
      status: 'planned',
    }).success).toBe(true);
  });

  it('rejects transfers within the same account', () => {
    const result = createTransferSchema.safeParse({
      fromAccountId: '00000000-0000-0000-0000-000000000001',
      toAccountId: '00000000-0000-0000-0000-000000000001',
      amount: '100.00',
      transferredAt: '2026-08-28',
    });
    expect(result.success).toBe(false);
  });

  it('rejects invalid budget month-style transaction filters', () => {
    const result = transactionQuerySchema.safeParse({
      from: '2026-02-30',
    });
    expect(result.success).toBe(false);
  });
});
