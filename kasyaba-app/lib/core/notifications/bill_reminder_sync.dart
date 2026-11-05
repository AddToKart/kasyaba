import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../connectivity/connectivity_service.dart';
import '../database/cache_service.dart';
import '../providers/api_providers.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

/// Keeps local bill reminders in step with the current bill list. Watched by
/// the app root so it stays active for the whole authenticated session.
final billReminderSyncProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  if (!isAuthenticated) return;

  final preferences = ref.watch(notificationPreferencesProvider);

  ref.listen<AsyncValue<List<BillItem>>>(billsProvider, (_, next) {
    if (next.hasError) {
      // Cold-start offline: the provider may surface an error instead of a
      // value. Re-arm reminders from the last saved bill snapshot so due-date
      // notifications still fire without a connection.
      if (ref.read(isOnlineProvider)) return;
      final userId = ref.read(authProvider).userId;
      if (userId == null) return;
      unawaited(_syncFromCachedSnapshot(ref, userId, preferences));
      return;
    }
    final bills = next.valueOrNull;
    if (bills == null) return;
    unawaited(
      NotificationService.instance.syncBillReminders(
        bills.map(_billToReminder),
        enabled: preferences.billReminders,
        defaultLeadDays: preferences.remindDaysBefore,
        timeOfDay: preferences.reminderTime,
      ),
    );
  }, fireImmediately: true);
});

BillReminder _billToReminder(BillItem bill) {
  return BillReminder(
    id: bill.id,
    name: bill.name,
    dueDate: bill.dueDate,
    status: bill.status,
    leadDays: bill.reminderLeadDays,
  );
}

/// Best-effort parse of the cached `bills` snapshot into reminders. Every row
/// and the whole decode are guarded so malformed legacy data can never take
/// down the app root or skip notification sync.
Future<void> _syncFromCachedSnapshot(
  Ref ref,
  String userId,
  NotificationPreferences preferences,
) async {
  try {
    final snapshot = await ref
        .read(cacheServiceProvider)
        .getSnapshot(userId, CacheService.snapshotKeyBills);
    if (snapshot == null) return;

    final decoded = jsonDecode(snapshot.json);
    if (decoded is! List) return;

    final reminders = <BillReminder>[];
    for (final row in decoded) {
      try {
        if (row is! Map) continue;
        final id = row['id']?.toString() ?? '';
        final name = row['name']?.toString() ?? '';
        final dueDate = DateTime.tryParse(row['dueDate']?.toString() ?? '');
        if (id.isEmpty || name.isEmpty || dueDate == null) continue;
        reminders.add(
          BillReminder(
            id: id,
            name: name,
            dueDate: dueDate,
            status: row['status']?.toString() ?? 'upcoming',
          ),
        );
      } catch (_) {
        // Skip malformed rows individually.
      }
    }

    if (reminders.isEmpty) return;
    await NotificationService.instance.syncBillReminders(
      reminders,
      enabled: preferences.billReminders,
      defaultLeadDays: preferences.remindDaysBefore,
      timeOfDay: preferences.reminderTime,
    );
  } catch (_) {
    // Cache re-arm is best effort.
  }
}
