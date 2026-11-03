import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/notifications/notification_preferences.dart';
import 'package:kasyaba/core/providers/preference_providers.dart';
import 'package:kasyaba/core/storage/secure_storage_service.dart';

class _FakeSecureStorage extends SecureStorageService {
  _FakeSecureStorage([Map<String, String>? seed])
    : values = <String, String>{...?seed};

  final Map<String, String> values;

  @override
  Future<String?> readRaw(String key) async => values[key];

  @override
  Future<void> writeRaw(String key, String value) async {
    values[key] = value;
  }
}

Future<void> _flushAsyncWork() => Future<void>.delayed(Duration.zero);

void main() {
  group('NotificationPreferences', () {
    test('uses defaults and clamps days before', () {
      final defaults = NotificationPreferences();
      expect(defaults.billReminders, true);
      expect(defaults.remindDaysBefore, 1);
      expect(defaults.budgetAlerts, true);
      expect(defaults.paydayReminder, true);
      expect(defaults.goalMilestones, true);
      expect(defaults.weeklySummary, false);
      expect(defaults.reminderTime, const TimeOfDay(hour: 9, minute: 0));

      expect(
        NotificationPreferences(remindDaysBefore: 99).remindDaysBefore,
        30,
      );
      expect(NotificationPreferences(remindDaysBefore: -5).remindDaysBefore, 0);
    });

    test('hydrates persisted values', () async {
      final storage = _FakeSecureStorage({
        NotificationPreferencesNotifier.billRemindersKey: 'false',
        NotificationPreferencesNotifier.remindDaysBeforeKey: '5',
        NotificationPreferencesNotifier.budgetAlertsKey: 'false',
        NotificationPreferencesNotifier.paydayReminderKey: 'false',
        NotificationPreferencesNotifier.goalMilestonesKey: 'false',
        NotificationPreferencesNotifier.weeklySummaryKey: 'true',
        NotificationPreferencesNotifier.reminderTimeKey: '18:45',
      });
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      container.read(notificationPreferencesProvider);
      await _flushAsyncWork();

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.billReminders, false);
      expect(prefs.remindDaysBefore, 5);
      expect(prefs.budgetAlerts, false);
      expect(prefs.paydayReminder, false);
      expect(prefs.goalMilestones, false);
      expect(prefs.weeklySummary, true);
      expect(prefs.reminderTime, const TimeOfDay(hour: 18, minute: 45));
    });

    test('ignores malformed stored values', () async {
      final storage = _FakeSecureStorage({
        NotificationPreferencesNotifier.billRemindersKey: 'not-a-bool',
        NotificationPreferencesNotifier.remindDaysBeforeKey: 'abc',
        NotificationPreferencesNotifier.reminderTimeKey: '99:99',
      });
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      container.read(notificationPreferencesProvider);
      await _flushAsyncWork();

      final prefs = container.read(notificationPreferencesProvider);
      expect(prefs.billReminders, true);
      expect(prefs.remindDaysBefore, 1);
      expect(prefs.reminderTime, const TimeOfDay(hour: 9, minute: 0));
    });

    test('persists updates', () async {
      final storage = _FakeSecureStorage();
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(notificationPreferencesProvider.notifier);
      notifier.setBillReminders(false);
      notifier.setRemindDaysBefore(4);
      notifier.setReminderTime(const TimeOfDay(hour: 7, minute: 5));
      await _flushAsyncWork();

      expect(
        storage.values[NotificationPreferencesNotifier.billRemindersKey],
        'false',
      );
      expect(
        storage.values[NotificationPreferencesNotifier.remindDaysBeforeKey],
        '4',
      );
      expect(
        storage.values[NotificationPreferencesNotifier.reminderTimeKey],
        '07:05',
      );
    });
  });

  group('ExcludedAccountsNotifier', () {
    test('defaults to empty and hydrates a stored set', () async {
      final storage = _FakeSecureStorage({
        ExcludedAccountsNotifier.storageKey: '["a2","a3"]',
      });
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      container.read(excludedAccountsProvider);
      await _flushAsyncWork();

      expect(container.read(excludedAccountsProvider), {'a2', 'a3'});
    });

    test('ignores malformed storage', () async {
      final storage = _FakeSecureStorage({
        ExcludedAccountsNotifier.storageKey: 'not-json',
      });
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      container.read(excludedAccountsProvider);
      await _flushAsyncWork();

      expect(container.read(excludedAccountsProvider), isEmpty);
    });

    test('toggles and persists account exclusions', () async {
      final storage = _FakeSecureStorage({
        ExcludedAccountsNotifier.storageKey: '["a2"]',
      });
      final container = ProviderContainer(
        overrides: [secureStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(excludedAccountsProvider.notifier);
      await _flushAsyncWork();

      expect(notifier.isExcluded('a2'), true);
      notifier.toggle('a2');
      notifier.toggle('a9');
      await _flushAsyncWork();

      expect(container.read(excludedAccountsProvider), {'a9'});
      expect(storage.values[ExcludedAccountsNotifier.storageKey], '["a9"]');
    });
  });
}
