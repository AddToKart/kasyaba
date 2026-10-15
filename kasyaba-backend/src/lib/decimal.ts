import Decimal from 'decimal.js';

type DecimalValue = Decimal | string | number;
type DecimalLike = { toString(): string };
type NullableDecimalValue = DecimalValue | DecimalLike | null | undefined;

export function toDecimal(value: DecimalValue): Decimal {
  if (value instanceof Decimal) return value;
  return new Decimal(value);
}

/**
 * Safely converts any database decimal value (including Prisma's Decimal or
 * null) without routing it through a JavaScript number first.
 */
export function toDecimalOrZero(value: NullableDecimalValue): Decimal {
  if (value === null || value === undefined) return new Decimal(0);
  if (value instanceof Decimal) return value;
  if (typeof value === 'number') return new Decimal(value);
  return new Decimal(value.toString());
}

export function toString(value: DecimalValue): string {
  return toDecimal(value).toFixed(2);
}

export function sumDecimals(values: DecimalValue[]): Decimal {
  return values.reduce<Decimal>((sum, v) => sum.plus(toDecimal(v)), new Decimal(0));
}

export function averageDecimals(values: DecimalValue[]): Decimal | null {
  if (values.length === 0) return null;
  return sumDecimals(values).div(values.length);
}

export function weightedAverage(
  values: { value: DecimalValue; weight: number }[]
): Decimal | null {
  if (values.length === 0) return null;
  const totalWeight = values.reduce((sum, v) => sum + v.weight, 0);
  if (totalWeight === 0) return null;
  const weightedSum = values.reduce<Decimal>(
    (sum, v) => sum.plus(toDecimal(v.value).times(v.weight)),
    new Decimal(0)
  );
  return weightedSum.div(totalWeight);
}
