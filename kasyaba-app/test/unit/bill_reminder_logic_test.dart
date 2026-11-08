import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/notifications/bill_reminder_logic.dart';

void main() {
  const reminderTime = TimeOfDay(hour: 9, minute: 0);

  group('resolveBillReminder', () {
    test('schedules when the lead-day time is still in the future', () {
      final decision = resolveBillReminder(
        billId: 'bill-1',
        dueDate: DateTime(2026, 11, 10),
        now: DateTime(2026, 11, 8, 8, 0),
        leadDays: 1,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.schedule);
      expect(decision.notifyAt, DateTime(2026, 11, 9, 9, 0));
      expect(decision.body, 'Due tomorrow');
      expect(decision.dedupeKey, isNull);
    });

    test('shows immediately when the lead-day time already passed', () {
      final decision = resolveBillReminder(
        billId: 'bill-1',
        dueDate: DateTime(2026, 11, 9),
        now: DateTime(2026, 11, 8, 10, 0),
        leadDays: 1,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.showNow);
      expect(decision.notifyAt, isNull);
      expect(decision.body, 'Due tomorrow');
      expect(decision.dedupeKey, 'bill-1:2026-11-09');
    });

    test('immediate body reflects the actual calendar-day distance', () {
      final decision = resolveBillReminder(
        billId: 'rent',
        dueDate: DateTime(2026, 11, 9),
        now: DateTime(2026, 11, 9, 12, 0),
        leadDays: 3,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.showNow);
      expect(decision.body, 'Due today');
      expect(decision.dedupeKey, 'rent:2026-11-09');
    });

    test('reuses the due-day key across immediate syncs on different days', () {
      final dueDate = DateTime(2026, 11, 9);

      final leadDayMissed = resolveBillReminder(
        billId: 'bill-1',
        dueDate: dueDate,
        now: DateTime(2026, 11, 8, 10, 0),
        leadDays: 1,
        time: reminderTime,
      );
      final dueDayMissed = resolveBillReminder(
        billId: 'bill-1',
        dueDate: dueDate,
        now: DateTime(2026, 11, 9, 10, 0),
        leadDays: 1,
        time: reminderTime,
      );

      expect(leadDayMissed.action, BillReminderAction.showNow);
      expect(dueDayMissed.action, BillReminderAction.showNow);
      expect(dueDayMissed.dedupeKey, leadDayMissed.dedupeKey);
    });

    test('treats a due time earlier today as still due today', () {
      final decision = resolveBillReminder(
        billId: 'bill-1',
        dueDate: DateTime(2026, 11, 8, 1, 0),
        now: DateTime(2026, 11, 8, 18, 0),
        leadDays: 1,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.showNow);
      expect(decision.body, 'Due today');
    });

    test('cancels when the local due day has already passed', () {
      final decision = resolveBillReminder(
        billId: 'bill-1',
        dueDate: DateTime(2026, 11, 7, 23, 59),
        now: DateTime(2026, 11, 8, 10, 0),
        leadDays: 1,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.cancel);
      expect(decision.notifyAt, isNull);
      expect(decision.dedupeKey, isNull);
    });

    test('scheduled body uses the configured lead window', () {
      final decision = resolveBillReminder(
        billId: 'bill-1',
        dueDate: DateTime(2026, 11, 15),
        now: DateTime(2026, 11, 8, 8, 0),
        leadDays: 3,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.schedule);
      expect(decision.notifyAt, DateTime(2026, 11, 12, 9, 0));
      expect(decision.body, 'Due in 3 days');
    });

    test('clamps negative lead days to the due day', () {
      final decision = resolveBillReminder(
        billId: 'bill-1',
        dueDate: DateTime(2026, 11, 10),
        now: DateTime(2026, 11, 8, 8, 0),
        leadDays: -5,
        time: reminderTime,
      );

      expect(decision.action, BillReminderAction.schedule);
      expect(decision.notifyAt, DateTime(2026, 11, 10, 9, 0));
      expect(decision.body, 'Due today');
    });
  });

  group('billReminderDedupeKey', () {
    test('formats the local calendar day with zero padding', () {
      expect(
        billReminderDedupeKey('bill-1', DateTime(2026, 1, 2, 23, 59)),
        'bill-1:2026-01-02',
      );
    });

    test('changes with the calendar day and bill id', () {
      expect(
        billReminderDedupeKey('a', DateTime(2026, 11, 8)),
        isNot(billReminderDedupeKey('a', DateTime(2026, 11, 9))),
      );
      expect(
        billReminderDedupeKey('a', DateTime(2026, 11, 8)),
        isNot(billReminderDedupeKey('b', DateTime(2026, 11, 8))),
      );
    });
  });
}
