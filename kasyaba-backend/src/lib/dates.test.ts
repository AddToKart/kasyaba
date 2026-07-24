import { describe, it, expect } from 'vitest';
import {
  toDateOnly,
  startOfMonth,
  endOfMonth,
  daysInMonth,
  daysBetween,
  addDays,
  addMonths,
  isSameDay,
  isSameMonth,
} from './dates';

describe('date utilities', () => {
  describe('toDateOnly', () => {
    it('zeroes out time components', () => {
      const d = new Date(2024, 0, 15, 10, 30, 45);
      const result = toDateOnly(d);
      expect(result.getHours()).toBe(0);
      expect(result.getMinutes()).toBe(0);
      expect(result.getSeconds()).toBe(0);
      expect(result.getMilliseconds()).toBe(0);
    });
  });

  describe('startOfMonth', () => {
    it('returns first day of month at midnight', () => {
      const d = new Date(2024, 5, 15);
      const result = startOfMonth(d);
      expect(result.getDate()).toBe(1);
      expect(result.getMonth()).toBe(5);
      expect(result.getFullYear()).toBe(2024);
    });
  });

  describe('endOfMonth', () => {
    it('returns last day of month', () => {
      const d = new Date(2024, 0, 15);
      const result = endOfMonth(d);
      expect(result.getDate()).toBe(31);
      expect(result.getMonth()).toBe(0);
    });

    it('handles February in leap year', () => {
      const d = new Date(2024, 1, 15);
      const result = endOfMonth(d);
      expect(result.getDate()).toBe(29);
    });

    it('handles February in non-leap year', () => {
      const d = new Date(2023, 1, 15);
      const result = endOfMonth(d);
      expect(result.getDate()).toBe(28);
    });
  });

  describe('daysInMonth', () => {
    it('returns correct days for January', () => {
      expect(daysInMonth(new Date(2024, 0, 1))).toBe(31);
    });

    it('returns correct days for February leap year', () => {
      expect(daysInMonth(new Date(2024, 1, 1))).toBe(29);
    });
  });

  describe('daysBetween', () => {
    it('returns positive difference', () => {
      const from = new Date(2024, 0, 1);
      const to = new Date(2024, 0, 10);
      expect(daysBetween(from, to)).toBe(9);
    });

    it('returns 0 for same day', () => {
      expect(daysBetween(new Date(2024, 0, 1), new Date(2024, 0, 1))).toBe(0);
    });

    it('returns 0 for past date', () => {
      expect(daysBetween(new Date(2024, 0, 10), new Date(2024, 0, 1))).toBe(0);
    });
  });

  describe('addDays', () => {
    it('adds days correctly', () => {
      const d = new Date(2024, 0, 1);
      const result = addDays(d, 31);
      expect(result.getDate()).toBe(1);
      expect(result.getMonth()).toBe(1);
    });
  });

  describe('addMonths', () => {
    it('adds months correctly', () => {
      const d = new Date(2024, 0, 15);
      const result = addMonths(d, 2);
      expect(result.getMonth()).toBe(2);
      expect(result.getFullYear()).toBe(2024);
    });
  });

  describe('isSameDay', () => {
    it('detects same day', () => {
      expect(isSameDay(new Date(2024, 0, 1), new Date(2024, 0, 1))).toBe(true);
    });

    it('detects different day', () => {
      expect(isSameDay(new Date(2024, 0, 1), new Date(2024, 0, 2))).toBe(false);
    });
  });

  describe('isSameMonth', () => {
    it('detects same month', () => {
      expect(isSameMonth(new Date(2024, 0, 1), new Date(2024, 0, 31))).toBe(true);
    });

    it('detects different month', () => {
      expect(isSameMonth(new Date(2024, 0, 1), new Date(2024, 1, 1))).toBe(false);
    });
  });
});
