import Decimal from 'decimal.js';

type DecimalValue = Decimal | string | number;

export function toDecimal(value: DecimalValue): Decimal {
  if (value instanceof Decimal) return value;
  return new Decimal(value);
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
