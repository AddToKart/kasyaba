import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../auth/widgets/auth_widgets.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Notifications Screen — 1:1 Pixel-Perfect Figma (Node 13:6204)
/// ─────────────────────────────────────────────────────────────
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);
    final topPadding = math.max(
      56.0,
      MediaQuery.of(context).padding.top + 16.0,
    );

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: DashboardTokens.ebony,
          gradient: DashboardTokens.canvasGradient,
        ),
        child: RefreshIndicator(
          color: DashboardTokens.periwinkleGray,
          backgroundColor: DashboardTokens.bigStone,
          onRefresh: () async {
            ref.invalidate(alertsProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 110),
            children: [
              // ── Header (Node 11:2427) ──────────────────────────
              FadeSlideEntrance.staggered(
                index: 0,
                child: _NotificationHeader(
                  onBackTap: () {
                    AppHaptics.selectionClick();
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),

              // ── Notifications Content ──────────────────────────
              alertsAsync.when(
                loading: () => FadeSlideEntrance.staggered(
                  index: 1,
                  child: const _NotificationsLoadingState(),
                ),
                error: (err, _) => FadeSlideEntrance.staggered(
                  index: 1,
                  child: _NotificationsErrorCard(
                    message: friendlyErrorMessage(err),
                    onRetry: () => ref.invalidate(alertsProvider),
                  ),
                ),
                data: (alerts) {
                  if (alerts.isEmpty) {
                    return FadeSlideEntrance.staggered(
                      index: 1,
                      child: const _NotificationsEmptyState(),
                    );
                  }

                  final now = DateTime.now();
                  final todayStart = DateTime(now.year, now.month, now.day);

                  final todayAlerts = alerts
                      .where((a) => !a.createdAt.isBefore(todayStart))
                      .toList();
                  final earlierAlerts = alerts
                      .where((a) => a.createdAt.isBefore(todayStart))
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // "TODAY" Section (Node 11:2433 & 11:2436)
                      if (todayAlerts.isNotEmpty) ...[
                        FadeSlideEntrance.staggered(
                          index: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionHeader(title: 'TODAY'),
                              const SizedBox(height: 8),
                              _NotificationGroupCard(
                                alerts: todayAlerts,
                                onAlertTap: (alert) =>
                                    _handleAlertTap(context, ref, alert),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Spacing between sections
                      if (todayAlerts.isNotEmpty && earlierAlerts.isNotEmpty)
                        const SizedBox(height: 20),

                      // "EARLIER" Section (Node 11:2458 & 11:2461)
                      if (earlierAlerts.isNotEmpty) ...[
                        FadeSlideEntrance.staggered(
                          index: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const _SectionHeader(title: 'EARLIER'),
                              const SizedBox(height: 8),
                              _NotificationGroupCard(
                                alerts: earlierAlerts,
                                onAlertTap: (alert) =>
                                    _handleAlertTap(context, ref, alert),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleAlertTap(
    BuildContext context,
    WidgetRef ref,
    AlertItem alert,
  ) async {
    AppHaptics.selectionClick();
    if (!alert.isRead) {
      try {
        final dio = ref.read(dioProvider);
        await dio.post('/alerts/${alert.id}/read');
        ref.invalidate(alertsProvider);
      } catch (e) {
        if (context.mounted) {
          KasyabaToast.showError(
            context,
            friendlyErrorMessage(
              e,
              fallback: 'Could not mark this notification as read.',
            ),
          );
        }
      }
    }
  }
}

/// ── Header with 50x50 Back Button & Bricolage Title (Node 11:2427) ──────
class _NotificationHeader extends StatelessWidget {
  final VoidCallback onBackTap;

  const _NotificationHeader({required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AuthBackButton(
          onPressed: onBackTap,
          size: 50,
          radius: 24,
          backgroundColor: DashboardTokens.bigStone,
          borderColor: DashboardTokens.poloBlue22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Notifications',
            style: GoogleFonts.bricolageGrotesque(
              color: DashboardTokens.periwinkleGray,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// ── Section Header: "TODAY", "EARLIER" (Node 11:2433 / 11:2458) ────────
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.dmSans(
          color: DashboardTokens.periwinkleGraySubtitle,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0, // 0.0833em
        ),
      ),
    );
  }
}

/// ── Group Container Card (Node 11:2436 / 11:2461) ──────────────────────
class _NotificationGroupCard extends StatelessWidget {
  final List<AlertItem> alerts;
  final ValueChanged<AlertItem> onAlertTap;

  const _NotificationGroupCard({
    required this.alerts,
    required this.onAlertTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
      child: Column(
        children: [
          for (int i = 0; i < alerts.length; i++) ...[
            if (i > 0) Container(height: 1, color: DashboardTokens.poloBlue16),
            _NotificationItemRow(
              alert: alerts[i],
              onTap: () => onAlertTap(alerts[i]),
            ),
          ],
        ],
      ),
    );
  }
}

/// ── Notification Item Row (Node 11:2437 / 11:2448 / 11:2462) ───────────
class _NotificationItemRow extends StatelessWidget {
  final AlertItem alert;
  final VoidCallback onTap;

  const _NotificationItemRow({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = !alert.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: DashboardTokens.periwinkleGray.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread Indicator Dot (Node 11:2438, 11:2439)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: SizedBox(
                  width: 10,
                  height: 16,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isUnread
                            ? DashboardTokens.apricot
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Subtitle Column (Node 11:2440)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      alert.title,
                      style: GoogleFonts.dmSans(
                        color: DashboardTokens.periwinkleGray,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alert.message,
                      style: GoogleFonts.dmSans(
                        color: DashboardTokens.periwinkleGraySubtitle,
                        fontSize: 14,
                        height: 20.3 / 14,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Timestamp (Node 11:2445, 11:2446)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _formatNotificationTime(alert.createdAt),
                  style: GoogleFonts.dmSans(
                    color: DashboardTokens.periwinkleGraySubtitle,
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatNotificationTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    final isToday =
        now.year == date.year && now.month == date.month && now.day == date.day;

    if (isToday) {
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 6) return '${diff.inHours}h';
      final hour = date.hour;
      final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final ampm = hour >= 12 ? 'pm' : 'am';
      return '$h$ampm';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final monthStr = months[date.month - 1];
    if (now.year == date.year) {
      return '$monthStr ${date.day}';
    }
    return '$monthStr ${date.day}, ${date.year}';
  }
}

/// ── Empty State ─────────────────────────────────────────────────────────
class _NotificationsEmptyState extends StatelessWidget {
  const _NotificationsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: DashboardTokens.ebony85,
              shape: BoxShape.circle,
              border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: DashboardTokens.periwinkleGray,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: GoogleFonts.bricolageGrotesque(
              color: DashboardTokens.periwinkleGray,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You\'re all caught up! Predictive insights and budget updates will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: DashboardTokens.periwinkleGraySubtitle,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// ── Loading Shimmer / Skeletons ─────────────────────────────────────────
class _NotificationsLoadingState extends StatelessWidget {
  const _NotificationsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const KasyabaLoadingSkeleton(lines: 5);
  }
}

/// ── Error State ─────────────────────────────────────────────────────────
class _NotificationsErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _NotificationsErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: DashboardTokens.apricot.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: DashboardTokens.apricot,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.dmSans(
                    color: DashboardTokens.apricot,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 16,
                color: DashboardTokens.periwinkleGray,
              ),
              label: Text(
                'Retry',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGray,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
