import { describe, it, expect } from 'vitest';
import {
  formatZonedDate,
  endOfZonedDay,
  startOfZonedDay,
  getZonedParts,
  startOfZonedMonth,
  endOfZonedMonth,
} from './zoned-dates';

describe('zoned-dates utilities', () => {
  it('formats dates into YYYY-MM-DD for Asia/Manila', () => {
    // 2026-10-14 16:00:00 UTC is 2026-10-15 00:00:00 in Asia/Manila (UTC+8)
    const instant = new Date('2026-10-14T16:00:00.000Z');
    expect(formatZonedDate(instant, 'Asia/Manila')).toBe('2026-10-15');
    expect(formatZonedDate(instant, 'UTC')).toBe('2026-10-14');
  });

  it('determines start and end of zoned day accurately', () => {
    // In Manila, 2026-10-15 starts at 2026-10-14T16:00:00Z and ends at 2026-10-15T15:59:59.999Z
    const instant = new Date('2026-10-15T02:00:00.000Z'); // 10:00 AM Manila
    const start = startOfZonedDay(instant, 'Asia/Manila');
    const end = endOfZonedDay(instant, 'Asia/Manila');

    expect(start.toISOString()).toBe('2026-10-14T16:00:00.000Z');
    expect(end.toISOString()).toBe('2026-10-15T15:59:59.999Z');
  });

  it('correctly provides zoned parts', () => {
    const instant = new Date('2026-09-01T04:00:00.000Z'); // 12:00 PM Manila on Sep 1
    const parts = getZonedParts(instant, 'Asia/Manila');
    expect(parts.year).toBe(2026);
    expect(parts.month).toBe(9);
    expect(parts.day).toBe(1);
  });
});

