import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

vi.mock('../../config/database', () => ({
  prisma: {
    user: { findUnique: vi.fn() },
    billTemplate: {
      findMany: vi.fn(),
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
    billInstance: {
      findUnique: vi.fn(),
      upsert: vi.fn(),
      deleteMany: vi.fn(),
      count: vi.fn(),
      findMany: vi.fn(),
    },
    expenseCategory: { findFirst: vi.fn() },
  },
}));

import { prisma } from '../../config/database';
import {
  createBillTemplate,
  generateBillInstances,
  listBills,
  updateBillTemplate,
} from './service';

const userId = 'user-1';
const templateId = 'template-1';

function makeTemplate(overrides: Record<string, unknown> = {}) {
  return {
    id: templateId,
    userId,
    name: 'Rent',
    defaultAmount: '1000.00',
    categoryId: null,
    recurrence: 'monthly' as const,
    dayOfWeek: null,
    dayOfMonth: null,
    startsOn: new Date('2026-05-06T00:00:00.000Z'),
    endsOn: null,
    reminderLeadDays: 1,
    isActive: true,
    createdAt: new Date('2026-05-01T00:00:00.000Z'),
    updatedAt: new Date('2026-05-01T00:00:00.000Z'),
    ...overrides,
  };
}

function isoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function upsertedDueDates(): Date[] {
  return vi.mocked(prisma.billInstance.upsert).mock.calls.map(
    (call) => (call[0] as any).create.dueDate as Date,
  );
}

function setNow(iso: string) {
  vi.useFakeTimers();
  vi.setSystemTime(new Date(iso));
}

beforeEach(() => {
  vi.clearAllMocks();
  vi.mocked(prisma.user.findUnique).mockResolvedValue({ timezone: 'UTC' } as never);
  vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([] as never);
  vi.mocked(prisma.billInstance.findUnique).mockResolvedValue(null);
  vi.mocked(prisma.billInstance.upsert).mockResolvedValue({} as never);
});

afterEach(() => {
  vi.useRealTimers();
});

describe('generateBillInstances', () => {
  it('does not backfill monthly instances when dayOfMonth is null', async () => {
    setNow('2026-11-06T10:00:00.000Z');
    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([
      makeTemplate({ startsOn: new Date('2026-05-06T00:00:00.000Z') }),
    ] as never);

    const created = await generateBillInstances(userId);

    expect(upsertedDueDates().map(isoDate)).toEqual([
      '2026-11-06',
      '2026-12-06',
      '2027-01-06',
    ]);
    expect(created).toBe(3);
  });

  it.each([
    ['UTC morning', '2026-11-06T05:00:00.000Z'],
    ['UTC afternoon', '2026-11-06T23:30:00.000Z'],
  ])('generates a bill due today when now is %s', async (_label, now) => {
    setNow(now);
    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([
      makeTemplate({
        startsOn: new Date('2026-11-06T00:00:00.000Z'),
        dayOfMonth: 6,
      }),
    ] as never);

    await generateBillInstances(userId);

    expect(upsertedDueDates().map(isoDate)).toEqual([
      '2026-11-06',
      '2026-12-06',
      '2027-01-06',
    ]);
  });

  it('keeps a 31st monthly anchor without permanent drift', async () => {
    setNow('2026-01-31T12:00:00.000Z');
    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([
      makeTemplate({
        startsOn: new Date('2026-01-31T00:00:00.000Z'),
        dayOfMonth: 31,
      }),
    ] as never);

    await generateBillInstances(userId);

    expect(upsertedDueDates().map(isoDate)).toEqual([
      '2026-01-31',
      '2026-02-28',
      '2026-03-31',
    ]);
  });

  it('anchors weekly occurrences to the startsOn weekday and skips past weeks', async () => {
    setNow('2026-11-06T10:00:00.000Z'); // Friday
    const startsOn = new Date('2026-10-12T00:00:00.000Z'); // Monday, ~3.5 weeks ago
    expect(startsOn.getUTCDay()).toBe(1);

    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([
      makeTemplate({
        recurrence: 'weekly',
        startsOn,
        dayOfWeek: null,
      }),
    ] as never);

    await generateBillInstances(userId);

    const dueDates = upsertedDueDates();
    expect(dueDates.length).toBeGreaterThan(0);
    expect(dueDates.every((date) => date.getUTCDay() === 1)).toBe(true);
    expect(dueDates[0]!.toISOString()).toBe('2026-11-09T00:00:00.000Z');
    expect(dueDates.every((date) => date >= new Date('2026-11-06T00:00:00.000Z'))).toBe(true);
  });

  it('keeps exactly one past occurrence for one-time bills', async () => {
    setNow('2026-11-06T10:00:00.000Z');
    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([
      makeTemplate({
        recurrence: 'none',
        startsOn: new Date('2026-09-15T00:00:00.000Z'),
      }),
    ] as never);

    const created = await generateBillInstances(userId);

    expect(upsertedDueDates().map(isoDate)).toEqual(['2026-09-15']);
    expect(created).toBe(1);
  });

  it('stops generating recurring instances after endsOn', async () => {
    setNow('2026-11-06T10:00:00.000Z');
    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([
      makeTemplate({
        startsOn: new Date('2026-05-06T00:00:00.000Z'),
        endsOn: new Date('2026-12-06T00:00:00.000Z'),
      }),
    ] as never);

    await generateBillInstances(userId);

    expect(upsertedDueDates().map(isoDate)).toEqual([
      '2026-11-06',
      '2026-12-06',
    ]);
  });
});

describe('createBillTemplate', () => {
  beforeEach(() => {
    setNow('2026-11-06T10:00:00.000Z');
    vi.mocked(prisma.billTemplate.create).mockResolvedValue({ id: templateId } as never);
  });

  it('derives dayOfMonth from startsOn for monthly templates', async () => {
    await createBillTemplate(userId, {
      name: 'Rent',
      defaultAmount: '1000.00',
      recurrence: 'monthly',
      startsOn: '2026-11-30',
      reminderLeadDays: 1,
      isActive: true,
    });

    expect(prisma.billTemplate.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        dayOfMonth: 30,
        dayOfWeek: null,
      }),
    });
  });

  it('derives dayOfWeek from startsOn for weekly templates', async () => {
    await createBillTemplate(userId, {
      name: 'Gym',
      defaultAmount: '500.00',
      recurrence: 'weekly',
      startsOn: '2026-11-09', // Monday
      reminderLeadDays: 1,
      isActive: true,
    });

    expect(prisma.billTemplate.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        dayOfWeek: 1,
        dayOfMonth: null,
      }),
    });
  });

  it('leaves one-time templates unchanged', async () => {
    await createBillTemplate(userId, {
      name: 'Repair',
      defaultAmount: '5000.00',
      recurrence: 'none',
      startsOn: '2026-11-30',
      reminderLeadDays: 1,
      isActive: true,
    });

    expect(prisma.billTemplate.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        dayOfMonth: null,
        dayOfWeek: null,
      }),
    });
  });
});

describe('updateBillTemplate', () => {
  it('deletes future unpaid instances and regenerates the schedule', async () => {
    setNow('2026-11-06T10:00:00.000Z');
    const existing = makeTemplate({ startsOn: new Date('2026-05-06T00:00:00.000Z') });
    const updated = { ...existing, defaultAmount: '1500.00' };

    vi.mocked(prisma.billTemplate.findFirst).mockResolvedValue(existing as never);
    vi.mocked(prisma.billTemplate.update).mockResolvedValue(updated as never);
    vi.mocked(prisma.billTemplate.findMany).mockResolvedValue([updated] as never);
    vi.mocked(prisma.billInstance.deleteMany).mockResolvedValue({ count: 2 } as never);

    await updateBillTemplate(userId, templateId, { defaultAmount: '1500.00' });

    expect(prisma.billInstance.deleteMany).toHaveBeenCalledWith({
      where: {
        userId,
        templateId,
        status: { notIn: ['paid', 'cancelled'] },
        dueDate: { gte: new Date('2026-11-06T00:00:00.000Z') },
      },
    });
    expect(upsertedDueDates().map(isoDate)).toEqual([
      '2026-11-06',
      '2026-12-06',
      '2027-01-06',
    ]);
  });
});

describe('listBills', () => {
  it('orders due dates descending so upcoming bills stay in the window', async () => {
    vi.mocked(prisma.billInstance.count).mockResolvedValue(0);
    vi.mocked(prisma.billInstance.findMany).mockResolvedValue([] as never);

    const result = await listBills(userId, { page: 1, limit: 10 });

    expect(prisma.billInstance.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ orderBy: { dueDate: 'desc' } }),
    );
    expect(result).toEqual({ rows: [], page: 1, limit: 10, total: 0 });
  });
});
