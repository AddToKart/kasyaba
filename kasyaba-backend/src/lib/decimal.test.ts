import { describe, it, expect } from 'vitest';
import { toDecimal, toString, sumDecimals, averageDecimals, weightedAverage } from './decimal';
import Decimal from 'decimal.js';

describe('decimal utilities', () => {
  describe('toDecimal', () => {
    it('converts from string', () => {
      const d = toDecimal('123.45');
      expect(d).toBeInstanceOf(Decimal);
      expect(d.toFixed(2)).toBe('123.45');
    });

    it('converts from number', () => {
      const d = toDecimal(123.45);
      expect(d.toFixed(2)).toBe('123.45');
    });

    it('returns Decimal instance as-is', () => {
      const orig = new Decimal('99.99');
      const d = toDecimal(orig);
      expect(d).toBe(orig);
    });
  });

  describe('toString', () => {
    it('formats with two decimal places', () => {
      expect(toString('100')).toBe('100.00');
      expect(toString('100.5')).toBe('100.50');
      expect(toString('100.123')).toBe('100.12');
    });
  });

  describe('sumDecimals', () => {
    it('sums an array of string amounts', () => {
      const result = sumDecimals(['10.50', '20.25', '5.25']);
      expect(result.toFixed(2)).toBe('36.00');
    });

    it('sums an empty array to zero', () => {
      expect(sumDecimals([]).toFixed(2)).toBe('0.00');
    });

    it('handles negative values', () => {
      expect(sumDecimals(['100', '-50', '25']).toFixed(2)).toBe('75.00');
    });
  });

  describe('averageDecimals', () => {
    it('returns average of values', () => {
      const result = averageDecimals(['10', '20', '30']);
      expect(result?.toFixed(2)).toBe('20.00');
    });

    it('returns null for empty array', () => {
      expect(averageDecimals([])).toBeNull();
    });
  });

  describe('weightedAverage', () => {
    it('calculates weighted average correctly', () => {
      const result = weightedAverage([
        { value: '100', weight: 0.5 },
        { value: '200', weight: 0.3 },
        { value: '150', weight: 0.2 },
      ]);
      // (100*0.5 + 200*0.3 + 150*0.2) / (0.5+0.3+0.2) = (50+60+30)/1.0 = 140
      expect(result?.toFixed(2)).toBe('140.00');
    });

    it('returns null for empty array', () => {
      expect(weightedAverage([])).toBeNull();
    });

    it('returns null for zero total weight', () => {
      expect(weightedAverage([{ value: '100', weight: 0 }])).toBeNull();
    });
  });
});
