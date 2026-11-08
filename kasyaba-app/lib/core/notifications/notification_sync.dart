import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_provider.dart';
import '../providers/api_providers.dart';
import '../storage/secure_storage_service.dart';
import 'notification_preferences.dart';
import 'notification_service.dart';

const String _seenAlertIdsKey = 'notif_seen_alert_ids';
const int _maxSeenAlertIds = 200;

const String _goalBucketsKey = 'notif_goal_buckets';
const int _maxTrackedGoalBuckets = 200;
const List<int> _goalMilestoneBuckets = <int>[25, 50, 75, 100];

/// Schedules the next payday reminder whenever auth, profile, or notification
/// preferences change.
final paydayReminderSyncProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  if (!isAuthenticated) return;

  final preferences = ref.watch(notificationPreferencesProvider);
  if (!preferences.paydayReminder) {
    unawaited(
      NotificationService.instance.syncPaydayReminder(
        enabled: false,
        frequency: null,
        schedule: null,
        timeOfDay: preferences.reminderTime,
      ),
    );
    return;
  }

  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile == null) return;

  unawaited(
    NotificationService.instance.syncPaydayReminder(
      enabled: true,
      frequency: profile.paydayFrequency,
      schedule: profile.paydaySchedule,
      timeOfDay: preferences.reminderTime,
    ),
  );
});

/// Surfaces newly-arrived financial alerts as local notifications.
///
/// The first successful emission seeds the seen-id set so pre-existing alerts
/// do not fire on app launch.
final alertNotificationSyncProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  if (!isAuthenticated) return;

  final budgetAlertsEnabled = ref.watch(
    notificationPreferencesProvider.select((prefs) => prefs.budgetAlerts),
  );
  if (!budgetAlertsEnabled) return;

  final storage = ref.watch(secureStorageProvider);
  var initialized = false;
  var seenIds = <String>{};
  var queue = Future<void>.value();

  Future<void> persistSeenIds() async {
    var ids = seenIds.toList();
    if (ids.length > _maxSeenAlertIds) {
      ids = ids.sublist(ids.length - _maxSeenAlertIds);
      seenIds = ids.toSet();
    }
    try {
      await storage.writeRaw(_seenAlertIdsKey, ids.join(','));
    } catch (_) {
      return;
    }
  }

  Future<void> processAlerts(List<AlertItem> alerts) async {
    try {
      if (!initialized) {
        final raw = await storage.readRaw(_seenAlertIdsKey);
        if (raw != null && raw.isNotEmpty) {
          seenIds = raw
              .split(',')
              .map((id) => id.trim())
              .where((id) => id.isNotEmpty)
              .toSet();
        }
        seenIds.addAll(alerts.map((alert) => alert.id));
        initialized = true;
        await persistSeenIds();
        return;
      }

      final unseenAlerts = alerts
          .where((alert) => !seenIds.contains(alert.id))
          .toList();
      if (unseenAlerts.isEmpty) return;

      for (final alert in unseenAlerts) {
        await NotificationService.instance.showInstantNotification(
          id: NotificationService.notificationIdFor(alert.id),
          title: alert.title,
          body: alert.message,
        );
        seenIds.add(alert.id);
      }
      await persistSeenIds();
    } catch (_) {
      return;
    }
  }

  ref.listen<AsyncValue<List<AlertItem>>>(alertsProvider, (_, next) {
    final alerts = next.valueOrNull;
    if (alerts == null) return;
    queue = queue.then((_) => processAlerts(alerts));
  }, fireImmediately: true);
});

/// Emits a notification when a savings goal crosses a 25/50/75/100% milestone.
///
/// The first successful emission seeds the bucket map so existing progress does
/// not fire on app launch.
final goalMilestoneSyncProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  if (!isAuthenticated) return;

  final goalMilestonesEnabled = ref.watch(
    notificationPreferencesProvider.select((prefs) => prefs.goalMilestones),
  );
  if (!goalMilestonesEnabled) return;

  final storage = ref.watch(secureStorageProvider);
  var initialized = false;
  var buckets = <String, int>{};
  var queue = Future<void>.value();

  int bucketFor(SavingsGoal goal) {
    final percent = (goal.progress * 100).floor();
    if (percent >= 100) return 100;
    if (percent >= 75) return 75;
    if (percent >= 50) return 50;
    if (percent >= 25) return 25;
    return 0;
  }

  Future<void> persistBuckets() async {
    if (buckets.length > _maxTrackedGoalBuckets) {
      final keys = buckets.keys.toList();
      for (final key in keys.take(buckets.length - _maxTrackedGoalBuckets)) {
        buckets.remove(key);
      }
    }
    try {
      await storage.writeRaw(_goalBucketsKey, jsonEncode(buckets));
    } catch (_) {
      return;
    }
  }

  Future<void> processGoals(List<SavingsGoal> goals) async {
    try {
      if (!initialized) {
        final raw = await storage.readRaw(_goalBucketsKey);
        if (raw != null && raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map<String, dynamic>) {
            buckets = decoded.map((key, value) {
              final parsed = value is num
                  ? value.toInt()
                  : int.tryParse(value.toString());
              return MapEntry<String, int>(key, parsed ?? 0);
            });
          }
        }
        for (final goal in goals) {
          buckets[goal.id] = bucketFor(goal);
        }
        initialized = true;
        await persistBuckets();
        return;
      }

      for (final goal in goals) {
        final currentBucket = bucketFor(goal);
        final previousBucket = buckets[goal.id] ?? 0;
        if (currentBucket <= previousBucket) {
          buckets.putIfAbsent(goal.id, () => currentBucket);
          continue;
        }

        for (final milestone in _goalMilestoneBuckets) {
          if (milestone > previousBucket && milestone <= currentBucket) {
            await NotificationService.instance.showInstantNotification(
              id: NotificationService.notificationIdFor(
                'goal_${goal.id}_$milestone',
              ),
              title: 'Goal milestone',
              body: '${goal.name} reached $milestone%',
            );
          }
        }
        buckets[goal.id] = currentBucket;
      }
      await persistBuckets();
    } catch (_) {
      return;
    }
  }

  ref.listen<AsyncValue<List<SavingsGoal>>>(goalsProvider, (_, next) {
    final goals = next.valueOrNull;
    if (goals == null) return;
    queue = queue.then((_) => processGoals(goals));
  }, fireImmediately: true);
});

/// Schedules (or cancels) the recurring Sunday weekly-summary notification.
final weeklySummarySyncProvider = Provider<void>((ref) {
  final isAuthenticated = ref.watch(
    authProvider.select((state) => state.isAuthenticated),
  );
  if (!isAuthenticated) return;

  final preferences = ref.watch(notificationPreferencesProvider);
  unawaited(
    NotificationService.instance.syncWeeklySummary(
      enabled: preferences.weeklySummary,
      timeOfDay: preferences.reminderTime,
    ),
  );
});
