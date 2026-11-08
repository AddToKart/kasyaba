import { describe, it, expect } from 'vitest';
import { requestLogSerializer } from './app';

describe('pino request serializer (privacy)', () => {
  it('strips query strings from the logged URL', () => {
    const serialized = requestLogSerializer({
      method: 'GET',
      url: '/api/v1/transactions?search=salary&from=2026-01-01',
    });

    expect(serialized).toEqual({
      method: 'GET',
      url: '/api/v1/transactions',
    });
  });

  it('never emits the client IP address', () => {
    const serialized = requestLogSerializer({
      method: 'POST',
      url: '/api/v1/auth/login',
      remoteAddress: '203.0.113.9',
    });

    expect(serialized).not.toHaveProperty('remoteAddress');
    expect(JSON.stringify(serialized)).not.toContain('203.0.113.9');
  });
});
