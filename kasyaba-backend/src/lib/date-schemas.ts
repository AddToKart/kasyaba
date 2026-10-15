import { z } from 'zod';
import { isValidTransactionDate } from './transaction-dates';

/**
 * Strict `YYYY-MM-DD` schema that rejects malformed and overflowing calendar
 * dates (for example `2026-99-99` or `2026-01-01junk`) before they reach
 * Prisma. The regex is anchored so trailing characters are never accepted.
 */
export const dateOnlySchema = z
  .string()
  .refine(
    (value) => /^\d{4}-\d{2}-\d{2}$/.test(value) && isValidTransactionDate(value),
    'Invalid calendar date (expected YYYY-MM-DD)',
  );

export const nullableDateOnlySchema = dateOnlySchema.nullable().optional();

/** Returns true when `endsOn` is absent or on/after `startsOn`. */
export function isOrderedRange(
  startsOn: string,
  endsOn: string | null | undefined,
): boolean {
  if (!endsOn) return true;
  // `YYYY-MM-DD` strings compare correctly lexicographically.
  return endsOn >= startsOn;
}
