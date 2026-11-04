import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/notifications/notification_preferences.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/figma_toggle_switch.dart';
import '../../../shared/widgets/kasyaba_date_picker.dart';
import '../../../shared/widgets/motion_components.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _daysLabel(int days) {
    return days == 1 ? '1 day before' : '$days days before';
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    WidgetRef ref,
    NotificationPreferences preferences,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: preferences.reminderTime,
      builder: (ctx, child) => Theme(
        data: kasyabaDatePickerTheme(ctx),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null) {
      ref
          .read(notificationPreferencesProvider.notifier)
          .setReminderTime(picked);
    }
  }

  void _cycleDaysBefore(WidgetRef ref, int currentDays) {
    const options = [1, 2, 3, 5, 7];
    final currentIndex = options.indexOf(currentDays);
    final nextIndex = (currentIndex + 1) % options.length;
    ref
        .read(notificationPreferencesProvider.notifier)
        .setRemindDaysBefore(options[nextIndex]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(notificationPreferencesProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final paydaySchedule = profileAsync.valueOrNull?.paydaySchedule;
    final notifier = ref.read(notificationPreferencesProvider.notifier);

    return Scaffold(
      backgroundColor: KasyabaTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(gradient: KasyabaTokens.canvasGradient),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, KasyabaTokens.dockClearance),
            children: [
              FadeSlideEntrance.staggered(
                index: 0,
                child: Row(
                  children: [
                    SpringTouch(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: KasyabaTokens.bigStone,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: KasyabaTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: KasyabaTokens.periwinkleGray,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Notifications',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideEntrance.staggered(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.bigStone,
                    borderRadius: BorderRadius.circular(
                      KasyabaTokens.radiusCard,
                    ),
                    border: Border.all(
                      color: KasyabaTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Bill reminders',
                        subtitle: 'Before each bill is due',
                        value: preferences.billReminders,
                        onChanged: notifier.setBillReminders,
                      ),
                      if (preferences.billReminders)
                        SpringTouch(
                          onTap: () => _cycleDaysBefore(
                            ref,
                            preferences.remindDaysBefore,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Text(
                                  'Remind me ',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: KasyabaTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                                Text(
                                  _daysLabel(preferences.remindDaysBefore),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: KasyabaTokens.periwinkleGray,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Container(height: 1, color: KasyabaTokens.poloBlue16),
                      _ToggleRow(
                        title: 'Budget alerts',
                        subtitle: 'At 80% and when you go over',
                        value: preferences.budgetAlerts,
                        onChanged: notifier.setBudgetAlerts,
                      ),
                      Container(height: 1, color: KasyabaTokens.poloBlue16),
                      _ToggleRow(
                        title: 'Payday reminder',
                        subtitle: paydaySchedule == null
                            ? 'On your payday schedule'
                            : 'On the $paydaySchedule',
                        value: preferences.paydayReminder,
                        onChanged: notifier.setPaydayReminder,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 19,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.bigStone,
                    borderRadius: BorderRadius.circular(
                      KasyabaTokens.radiusCard,
                    ),
                    border: Border.all(
                      color: KasyabaTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _ToggleRow(
                        title: 'Goal milestones',
                        subtitle: 'When a goal reaches 25%, 50%, 75%',
                        value: preferences.goalMilestones,
                        onChanged: notifier.setGoalMilestones,
                      ),
                      Container(height: 1, color: KasyabaTokens.poloBlue16),
                      _ToggleRow(
                        title: 'Weekly summary',
                        subtitle: 'Every Sunday evening',
                        value: preferences.weeklySummary,
                        onChanged: notifier.setWeeklySummary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 3,
                child: SpringTouch(
                  onTap: () => _pickReminderTime(context, ref, preferences),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 21,
                      vertical: 18.5,
                    ),
                    decoration: BoxDecoration(
                      color: KasyabaTokens.bigStone,
                      borderRadius: BorderRadius.circular(
                        KasyabaTokens.radiusCard,
                      ),
                      border: Border.all(
                        color: KasyabaTokens.poloBlue22,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            'Time',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: KasyabaTokens.periwinkleGraySubtitle,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _formatTimeOfDay(preferences.reminderTime),
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: KasyabaTokens.periwinkleGray,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.access_time_rounded,
                          color: KasyabaTokens.periwinkleGraySubtitle,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideEntrance.staggered(
                index: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Reminders are scheduled on your device, so they work offline.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: KasyabaTokens.periwinkleGraySubtitle,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KasyabaTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: KasyabaTokens.periwinkleGraySubtitle,
                  ),
                ),
              ],
            ),
          ),
          FigmaToggleSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
