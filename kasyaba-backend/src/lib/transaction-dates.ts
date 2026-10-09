const DATE_ONLY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const LOCAL_DATE_TIME_PATTERN =
  /^(\d{4})-(\d{2})-(\d{2})T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,9})?)?(?:Z|[+-]\d{2}:\d{2})?$/;

function isValidCalendarDate(year: number, month: number, day: number): boolean {
  if (year < 1 || month < 1 || month > 12 || day < 1) return false;

  const date = createUtcDate(year, month, day);
  return date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day;
}

function createUtcDate(year: number, month: number, day: number): Date {
  // Date.UTC treats years 0–99 as 1900–1999, so set the full year after
  // creating the value to keep date-only parsing correct for every year.
  const date = new Date(0);
  date.setUTCFullYear(year, month - 1, day);
  date.setUTCHours(0, 0, 0, 0);
  return date;
}

export function isValidTransactionDate(value: string): boolean {
  const dateOnlyMatch = DATE_ONLY_PATTERN.exec(value);
  const dateTimeMatch = LOCAL_DATE_TIME_PATTERN.exec(value);
  const match = dateOnlyMatch ?? dateTimeMatch;
  if (!match) return false;

  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (!isValidCalendarDate(year, month, day)) return false;

  return dateOnlyMatch != null || Number.isFinite(Date.parse(value));
}

export function parseTransactionDate(value: string): Date {
  const match = DATE_ONLY_PATTERN.exec(value);
  if (match) {
    return createUtcDate(
      Number(match[1]),
      Number(match[2]),
      Number(match[3]),
    );
  }

  const parsed = new Date(value);
  if (!Number.isFinite(parsed.getTime())) {
    throw new Error('Invalid transaction date');
  }
  return parsed;
}

export function parseDateOnlyStart(value: string): Date {
  const match = DATE_ONLY_PATTERN.exec(value);
  if (!match || !isValidTransactionDate(value)) {
    throw new Error('Invalid calendar date');
  }
  return createUtcDate(
    Number(match[1]),
    Number(match[2]),
    Number(match[3]),
  );
}

export function parseDateOnlyEnd(value: string): Date {
  const start = parseDateOnlyStart(value);
  return new Date(start.getTime() + 24 * 60 * 60 * 1000 - 1);
}
