import 'dart:math' as math;

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../utils/deterministic_math.dart';

/// A bill occurrence that should (or should no longer) have a local reminder.
class BillReminder {
  const BillReminder({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.status,
    this.leadDays,
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final String status;

  /// Per-bill override for how many days before the due date to notify.
  final int? leadDays;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'bill_reminders';
  static const _channelName = 'Bill Reminders';
  static const _channelDescription = 'Reminders for upcoming bills';

  static const _instantChannelId = 'financial_alerts';
  static const _instantChannelName = 'Financial alerts';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    // Reminders are scheduled as absolute instants (see [_schedule]), so the
    // device wall-clock location is not required. `tz.UTC` is used explicitly
    // instead of relying on the misleading default `tz.local`.

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _plugin.initialize(settings);
    } catch (_) {
      // The plugin is unavailable in some environments (e.g. unit tests).
      return;
    }

    // Permission requests must never crash startup (for example when the
    // Android 13+ permission dialog cannot be shown).
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.requestNotificationsPermission();

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {
      // Permission can also be requested later from system settings.
      return;
    }
  }

  /// Keeps local reminders in step with the current bill list: every upcoming
  /// bill gets a reminder [leadDays] before its due date at [timeOfDay], and
  /// paid/cancelled/overdue bills have their reminder cancelled.
  Future<void> syncBillReminders(
    Iterable<BillReminder> reminders, {
    bool enabled = true,
    int defaultLeadDays = 1,
    TimeOfDay timeOfDay = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    for (final reminder in reminders) {
      final id = notificationIdFor('bill_${reminder.id}');
      if (!enabled || reminder.status != 'upcoming') {
        await _cancel(id);
        continue;
      }

      final leadDays = math.max(0, reminder.leadDays ?? defaultLeadDays);
      final dueDay = DateTime(
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      final notifyAt = dueDay.subtract(Duration(days: leadDays));
      if (!notifyAt.isAfter(DateTime.now())) {
        await _cancel(id);
        continue;
      }

      await _schedule(id, reminder.name, _billReminderBody(leadDays), notifyAt);
    }
  }

  /// Shows an immediate notification (used for alert/goal-milestone sync).
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String channelId = _instantChannelId,
    String channelName = _instantChannelName,
  }) async {
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: 'Alerts and updates from Kasyaba',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _plugin.show(id, title, body, details);
    } catch (_) {
      return;
    }
  }

  /// Schedules a single reminder for the next payday, or cancels it when the
  /// payday reminder preference is disabled.
  Future<void> syncPaydayReminder({
    required bool enabled,
    required String? frequency,
    required String? schedule,
    TimeOfDay timeOfDay = const TimeOfDay(hour: 9, minute: 0),
  }) async {
    final id = notificationIdFor('payday_reminder');
    try {
      if (!enabled) {
        await _plugin.cancel(id);
        return;
      }

      final nextPayday = computeNextPayday(
        DateTime.now(),
        frequency: frequency,
        schedule: schedule,
      );
      final notifyAt = DateTime(
        nextPayday.year,
        nextPayday.month,
        nextPayday.day,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      if (!notifyAt.isAfter(DateTime.now())) {
        await _plugin.cancel(id);
        return;
      }

      await _schedule(id, 'Payday', 'Your payday is today.', notifyAt);
    } catch (_) {
      return;
    }
  }

  /// Schedules a recurring weekly summary notification for Sunday at
  /// [timeOfDay], or cancels it when disabled.
  Future<void> syncWeeklySummary({
    required bool enabled,
    required TimeOfDay timeOfDay,
  }) async {
    final id = notificationIdFor('weekly_summary');
    try {
      if (!enabled) {
        await _plugin.cancel(id);
        return;
      }

      final now = DateTime.now();
      final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
      var scheduled = DateTime(
        now.year,
        now.month,
        now.day + daysUntilSunday,
        timeOfDay.hour,
        timeOfDay.minute,
      );
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }

      await _schedule(
        id,
        'Weekly summary',
        'Review your week in Kasyaba.',
        scheduled,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (_) {
      return;
    }
  }

  Future<void> cancelNotification(int id) async {
    await _cancel(id);
  }

  Future<void> _cancel(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (_) {
      return;
    }
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime scheduledDate, {
    DateTimeComponents? matchDateTimeComponents,
    String channelId = _channelId,
    String channelName = _channelName,
    String channelDescription = _channelDescription,
  }) async {
    try {
      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      await _plugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.UTC),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (_) {
      return;
    }
  }

  static String _billReminderBody(int leadDays) {
    if (leadDays <= 0) return 'Due today';
    if (leadDays == 1) return 'Due tomorrow';
    return 'Due in $leadDays days';
  }

  /// Stable FNV-1a hash so the same key always maps to the same notification
  /// id (Dart's `String.hashCode` is not a stable contract across runs).
  static int notificationIdFor(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
