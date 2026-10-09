interface ZonedParts {
  year: number;
  month: number;
  day: number;
  hour: number;
  minute: number;
  second: number;
}

function formatterFor(timeZone: string): Intl.DateTimeFormat {
  try {
    return new Intl.DateTimeFormat('en-US', {
      timeZone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    });
  } catch {
    return new Intl.DateTimeFormat('en-US', {
      timeZone: 'UTC',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    });
  }
}

function partsFor(date: Date, timeZone: string): ZonedParts {
  const parts = formatterFor(timeZone).formatToParts(date);
  const values = new Map(parts.map((part) => [part.type, Number(part.value)]));
  return {
    year: values.get('year') ?? date.getUTCFullYear(),
    month: values.get('month') ?? date.getUTCMonth() + 1,
    day: values.get('day') ?? date.getUTCDate(),
    hour: values.get('hour') ?? date.getUTCHours(),
    minute: values.get('minute') ?? date.getUTCMinutes(),
    second: values.get('second') ?? date.getUTCSeconds(),
  };
}

function utcForLocal(parts: ZonedParts, timeZone: string): Date {
  const guess = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    parts.second,
  );
  const observed = partsFor(new Date(guess), timeZone);
  const observedAsUtc = Date.UTC(
    observed.year,
    observed.month - 1,
    observed.day,
    observed.hour,
    observed.minute,
    observed.second,
  );
  return new Date(guess - (observedAsUtc - guess));
}

export function startOfZonedDay(date: Date, timeZone: string): Date {
  const parts = partsFor(date, timeZone);
  return utcForLocal({ ...parts, hour: 0, minute: 0, second: 0 }, timeZone);
}

export function startOfZonedMonth(date: Date, timeZone: string): Date {
  const parts = partsFor(date, timeZone);
  return utcForLocal({ year: parts.year, month: parts.month, day: 1, hour: 0, minute: 0, second: 0 }, timeZone);
}

export function endOfZonedMonth(date: Date, timeZone: string): Date {
  const parts = partsFor(date, timeZone);
  const nextMonth = new Date(Date.UTC(parts.year, parts.month, 1));
  const nextParts = {
    year: nextMonth.getUTCFullYear(),
    month: nextMonth.getUTCMonth() + 1,
    day: nextMonth.getUTCDate(),
    hour: 0,
    minute: 0,
    second: 0,
  };
  return new Date(utcForLocal(nextParts, timeZone).getTime() - 1);
}
