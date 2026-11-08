import 'dart:math' as math;

import 'package:flutter/material.dart' show TimeOfDay;

/// The action a bill sync should take for a single upcoming bill.
enum BillReminderAction { cancel, schedule, showNow }

/// Pure, testable outcome of [resolveBillReminder].
class BillReminderDecision {
  const BillReminderDecision({
    required this.action,
    this.notifyAt,
    this.body = '',
    this.dedupeKey,
  });

  final BillReminderAction action;

  /// Scheduled instant for [BillReminderAction.schedule]; null otherwise.
  final DateTime? notifyAt;

  /// Notification body (empty for [BillReminderAction.cancel]).
  final String body;

  /// Session dedupe key for [BillReminderAction.showNow]; null otherwise.
  final String? dedupeKey;
}

/// Decides how an upcoming bill reminder should be handled.
///
/// Reminders are normally scheduled [leadDays] before the bill's local
/// calendar due day at [time]. When that instant has already passed but the
/// bill is still due today or later, the lead-day window was missed (for
/// example a sync ran after 09:00 on the lead day), so the caller should show
/// an immediate notification instead. Bills whose local due day has already
/// passed are cancelled and never scheduled.
BillReminderDecision resolveBillReminder({
  required String billId,
  required DateTime dueDate,
  required DateTime now,
  required int leadDays,
  required TimeOfDay time,
}) {
  final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final today = DateTime(now.year, now.month, now.day);
  final effectiveLeadDays = math.max(0, leadDays);
  final notifyAt = DateTime(
    dueDay.year,
    dueDay.month,
    dueDay.day,
    time.hour,
    time.minute,
  ).subtract(Duration(days: effectiveLeadDays));

  if (notifyAt.isAfter(now)) {
    return BillReminderDecision(
      action: BillReminderAction.schedule,
      notifyAt: notifyAt,
      body: billReminderBody(effectiveLeadDays),
    );
  }

  if (!dueDay.isBefore(today)) {
    final daysUntilDue = dueDay.difference(today).inDays;
    return BillReminderDecision(
      action: BillReminderAction.showNow,
      body: billReminderBody(daysUntilDue),
      dedupeKey: billReminderDedupeKey(billId, dueDay),
    );
  }

  return const BillReminderDecision(action: BillReminderAction.cancel);
}

/// Body copy that reflects how many calendar days remain before the due date.
String billReminderBody(int daysUntilDue) {
  if (daysUntilDue <= 0) return 'Due today';
  if (daysUntilDue == 1) return 'Due tomorrow';
  return 'Due in $daysUntilDue days';
}

/// Stable session key (`<billId>:<yyyy-mm-dd>`) built from the bill's local
/// due day, so one bill occurrence only ever produces one immediate reminder
/// during a session.
String billReminderDedupeKey(String billId, DateTime day) {
  final date =
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
  return '$billId:$date';
}
