import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/figma_toggle_switch.dart';
import '../../../shared/widgets/motion_components.dart';

/// ─────────────────────────────────────────────────────────────
///  1:1 Figma Notification Settings Screen (Node 42:6899)
/// ─────────────────────────────────────────────────────────────
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _billReminders = true;
  int _remindDaysBefore = 3;
  bool _budgetAlerts = true;
  bool _paydayReminder = true;
  bool _goalMilestones = false;
  bool _weeklySummary = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DashboardTokens.periwinkleGray,
              onPrimary: DashboardTokens.ebony,
              surface: DashboardTokens.bigStone,
              onSurface: DashboardTokens.periwinkleGray,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  void _cycleDaysBefore() {
    final options = [1, 2, 3, 5, 7];
    final currentIndex = options.indexOf(_remindDaysBefore);
    final nextIndex = (currentIndex + 1) % options.length;
    setState(() => _remindDaysBefore = options[nextIndex]);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    // Header row: 50x50 squircle back button + Title
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
                                color: DashboardTokens.bigStone,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: DashboardTokens.poloBlue22,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: DashboardTokens.periwinkleGray,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Group 1 Card: Bill reminders, Budget alerts, Payday reminder
                    FadeSlideEntrance.staggered(
                      index: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Bill reminders
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Bill reminders',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.periwinkleGray,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Before each bill is due',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FigmaToggleSwitch(
                                    value: _billReminders,
                                    onChanged: (val) =>
                                        setState(() => _billReminders = val),
                                  ),
                                ],
                              ),
                            ),

                            // Remind me X days before (sub-row)
                            if (_billReminders)
                              SpringTouch(
                                onTap: _cycleDaysBefore,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      const Text(
                                        'Remind me ',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: DashboardTokens.periwinkleGraySubtitle,
                                        ),
                                      ),
                                      Text(
                                        '$_remindDaysBefore days before',
                                        style: const TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.periwinkleGray,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // Divider
                            Container(
                              height: 1,
                              color: DashboardTokens.poloBlue16,
                            ),

                            // Budget alerts
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Budget alerts',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.periwinkleGray,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'At 80% and when you go over',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FigmaToggleSwitch(
                                    value: _budgetAlerts,
                                    onChanged: (val) =>
                                        setState(() => _budgetAlerts = val),
                                  ),
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              height: 1,
                              color: DashboardTokens.poloBlue16,
                            ),

                            // Payday reminder
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Payday reminder',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.periwinkleGray,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'On the 15th and 30th',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FigmaToggleSwitch(
                                    value: _paydayReminder,
                                    onChanged: (val) =>
                                        setState(() => _paydayReminder = val),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Group 2 Card: Goal milestones, Weekly summary
                    FadeSlideEntrance.staggered(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Goal milestones
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Goal milestones',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.periwinkleGray,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'When a goal reaches 25%, 50%, 75%',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FigmaToggleSwitch(
                                    value: _goalMilestones,
                                    onChanged: (val) =>
                                        setState(() => _goalMilestones = val),
                                  ),
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              height: 1,
                              color: DashboardTokens.poloBlue16,
                            ),

                            // Weekly summary
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: const [
                                        Text(
                                          'Weekly summary',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.periwinkleGray,
                                          ),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Every Sunday evening',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FigmaToggleSwitch(
                                    value: _weeklySummary,
                                    onChanged: (val) =>
                                        setState(() => _weeklySummary = val),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Time Picker Row
                    FadeSlideEntrance.staggered(
                      index: 3,
                      child: SpringTouch(
                        onTap: _pickReminderTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 18.5),
                          decoration: BoxDecoration(
                            color: DashboardTokens.bigStone,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: DashboardTokens.poloBlue22,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 96,
                                child: Text(
                                  'Time',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _formatTimeOfDay(_reminderTime),
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.access_time_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Footnote
                    FadeSlideEntrance.staggered(
                      index: 4,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          'Reminders are scheduled on your device, so they work offline.',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: DashboardTokens.periwinkleGraySubtitle,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
