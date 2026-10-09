import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// A bill occurrence that should (or should no longer) have a local reminder.
class BillReminder {
  const BillReminder({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final String status;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'bill_reminders';
  static const _channelName = 'Bill Reminders';
  static const _channelDescription = 'Reminders for upcoming bills';

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
    await _plugin.initialize(settings);

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
    }
  }

  /// Keeps local reminders in step with the current bill list: every upcoming
  /// bill gets a reminder the day before at 09:00, and paid/cancelled/overdue
  /// bills have their reminder cancelled.
  Future<void> syncBillReminders(Iterable<BillReminder> reminders) async {
    for (final reminder in reminders) {
      final id = _notificationId('bill_${reminder.id}');
      if (reminder.status != 'upcoming') {
        await _plugin.cancel(id);
        continue;
      }

      final dueDay = DateTime(
        reminder.dueDate.year,
        reminder.dueDate.month,
        reminder.dueDate.day,
        9,
      );
      final notifyAt = dueDay.subtract(const Duration(days: 1));
      if (!notifyAt.isAfter(DateTime.now())) {
        await _plugin.cancel(id);
        continue;
      }

      await _schedule(id, reminder.name, 'Due tomorrow', notifyAt);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  Future<void> _schedule(
    int id,
    String title,
    String body,
    DateTime scheduledDate,
  ) async {
    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
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
    );
  }

  /// Stable FNV-1a hash so the same bill always maps to the same notification
  /// id (Dart's `String.hashCode` is not a stable contract across runs).
  static int _notificationId(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
