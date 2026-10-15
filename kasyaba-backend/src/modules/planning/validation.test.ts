import { describe, expect, it } from 'vitest';
import { planningQuerySchema } from './validation';

describe('planningQuerySchema', () => {
  it('accepts a window up to 91 days', () => {
    const result = planningQuerySchema.safeParse({ from: '2026-08-29', to: '2026-11-27' });
    expect(result.success).toBe(true);
  });

  it('rejects reversed or oversized windows', () => {
    expect(planningQuerySchema.safeParse({ from: '2026-08-30', to: '2026-08-29' }).success).toBe(false);
    expect(planningQuerySchema.safeParse({ from: '2026-08-29', to: '2027-01-01' }).success).toBe(false);
  });
});
