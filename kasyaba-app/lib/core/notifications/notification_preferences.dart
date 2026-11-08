import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';

/// Persisted, user-facing notification preferences.
///
/// The notifier starts with sane defaults so the UI can render immediately and
/// then hydrates from secure storage asynchronously.
class NotificationPreferences {
  NotificationPreferences({
    this.billReminders = true,
    int remindDaysBefore = 1,
    this.budgetAlerts = true,
    this.paydayReminder = true,
    this.goalMilestones = true,
    this.weeklySummary = false,
    this.reminderTime = const TimeOfDay(hour: 9, minute: 0),
  }) : remindDaysBefore = remindDaysBefore.clamp(0, 30).toInt();

  final bool billReminders;
  final int remindDaysBefore;
  final bool budgetAlerts;
  final bool paydayReminder;
  final bool goalMilestones;
  final bool weeklySummary;
  final TimeOfDay reminderTime;

  NotificationPreferences copyWith({
    bool? billReminders,
    int? remindDaysBefore,
    bool? budgetAlerts,
    bool? paydayReminder,
    bool? goalMilestones,
    bool? weeklySummary,
    TimeOfDay? reminderTime,
  }) {
    return NotificationPreferences(
      billReminders: billReminders ?? this.billReminders,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
      budgetAlerts: budgetAlerts ?? this.budgetAlerts,
      paydayReminder: paydayReminder ?? this.paydayReminder,
      goalMilestones: goalMilestones ?? this.goalMilestones,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<
      NotificationPreferencesNotifier,
      NotificationPreferences
    >((ref) {
      return NotificationPreferencesNotifier(ref.watch(secureStorageProvider));
    });

class NotificationPreferencesNotifier
    extends StateNotifier<NotificationPreferences> {
  NotificationPreferencesNotifier(this._storage)
    : super(NotificationPreferences()) {
    unawaited(_load());
  }

  static const billRemindersKey = 'notif_bill_reminders';
  static const remindDaysBeforeKey = 'notif_remind_days_before';
  static const budgetAlertsKey = 'notif_budget_alerts';
  static const paydayReminderKey = 'notif_payday_reminder';
  static const goalMilestonesKey = 'notif_goal_milestones';
  static const weeklySummaryKey = 'notif_weekly_summary';
  static const reminderTimeKey = 'notif_reminder_time';

  final SecureStorageService _storage;
  final Set<String> _locallyModified = <String>{};

  Future<void> _load() async {
    try {
      final values = await Future.wait<String?>([
        _storage.readRaw(billRemindersKey),
        _storage.readRaw(remindDaysBeforeKey),
        _storage.readRaw(budgetAlertsKey),
        _storage.readRaw(paydayReminderKey),
        _storage.readRaw(goalMilestonesKey),
        _storage.readRaw(weeklySummaryKey),
        _storage.readRaw(reminderTimeKey),
      ]);

      final current = state;
      state = current.copyWith(
        billReminders: _locallyModified.contains(billRemindersKey)
            ? current.billReminders
            : _parseBool(values[0], current.billReminders),
        remindDaysBefore: _locallyModified.contains(remindDaysBeforeKey)
            ? current.remindDaysBefore
            : _parseDaysBefore(values[1], current.remindDaysBefore),
        budgetAlerts: _locallyModified.contains(budgetAlertsKey)
            ? current.budgetAlerts
            : _parseBool(values[2], current.budgetAlerts),
        paydayReminder: _locallyModified.contains(paydayReminderKey)
            ? current.paydayReminder
            : _parseBool(values[3], current.paydayReminder),
        goalMilestones: _locallyModified.contains(goalMilestonesKey)
            ? current.goalMilestones
            : _parseBool(values[4], current.goalMilestones),
        weeklySummary: _locallyModified.contains(weeklySummaryKey)
            ? current.weeklySummary
            : _parseBool(values[5], current.weeklySummary),
        reminderTime: _locallyModified.contains(reminderTimeKey)
            ? current.reminderTime
            : _parseTime(values[6], current.reminderTime),
      );
    } catch (_) {
      return;
    }
  }

  void setBillReminders(bool value) {
    _locallyModified.add(billRemindersKey);
    state = state.copyWith(billReminders: value);
    _persist(billRemindersKey, value ? 'true' : 'false');
  }

  void setRemindDaysBefore(int value) {
    final clamped = value.clamp(0, 30).toInt();
    _locallyModified.add(remindDaysBeforeKey);
    state = state.copyWith(remindDaysBefore: clamped);
    _persist(remindDaysBeforeKey, '$clamped');
  }

  void setBudgetAlerts(bool value) {
    _locallyModified.add(budgetAlertsKey);
    state = state.copyWith(budgetAlerts: value);
    _persist(budgetAlertsKey, value ? 'true' : 'false');
  }

  void setPaydayReminder(bool value) {
    _locallyModified.add(paydayReminderKey);
    state = state.copyWith(paydayReminder: value);
    _persist(paydayReminderKey, value ? 'true' : 'false');
  }

  void setGoalMilestones(bool value) {
    _locallyModified.add(goalMilestonesKey);
    state = state.copyWith(goalMilestones: value);
    _persist(goalMilestonesKey, value ? 'true' : 'false');
  }

  void setWeeklySummary(bool value) {
    _locallyModified.add(weeklySummaryKey);
    state = state.copyWith(weeklySummary: value);
    _persist(weeklySummaryKey, value ? 'true' : 'false');
  }

  void setReminderTime(TimeOfDay value) {
    _locallyModified.add(reminderTimeKey);
    state = state.copyWith(reminderTime: value);
    _persist(reminderTimeKey, _formatTime(value));
  }

  void _persist(String key, String value) {
    unawaited(_write(key, value));
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.writeRaw(key, value);
    } catch (_) {
      return;
    }
  }

  static bool _parseBool(String? raw, bool fallback) {
    if (raw == null) return fallback;
    switch (raw.trim().toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return fallback;
    }
  }

  static int _parseDaysBefore(String? raw, int fallback) {
    final parsed = int.tryParse(raw?.trim() ?? '');
    if (parsed == null) return fallback;
    return parsed.clamp(0, 30).toInt();
  }

  static TimeOfDay _parseTime(String? raw, TimeOfDay fallback) {
    if (raw == null) return fallback;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(raw.trim());
    if (match == null) return fallback;
    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return fallback;
    }
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
