import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dashboardAsync = ref.watch(dashboardProvider);
    final alertsAsync = ref.watch(alertsProvider);
    final recoveryAsync = ref.watch(recoveryAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Predictive Financial Alerts',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.invalidate(alertsProvider);
              ref.invalidate(recoveryAnalysisProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All alerts refreshed')),
              );
            },
            child: Text(
              'Refresh',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(alertsProvider);
          ref.invalidate(recoveryAnalysisProvider);
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // ── Dynamic Health Score Header Banner ─────────────────────────
            dashboardAsync.when(
              loading: () => const SizedBox(
                height: 90,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading health score: $err'),
              ),
              data: (data) {
                final grade = data.healthScore; // 'Needs Attention', 'Fair', 'Good', 'Excellent'
                List<Color> gradientColors;
                IconData headerIcon;

                if (grade == 'Needs Attention' || grade == 'Critical') {
                  gradientColors = const [Color(0xFFDC2626), Color(0xFFEF4444)];
                  headerIcon = Icons.warning_amber_rounded;
                } else if (grade == 'Fair') {
                  gradientColors = const [Color(0xFFD97706), Color(0xFFF59E0B)];
                  headerIcon = Icons.info_outline_rounded;
                } else {
                  gradientColors = const [Color(0xFF059669), Color(0xFF10B981)];
                  headerIcon = Icons.health_and_safety_rounded;
                }

                return ModernCard(
                  padding: const EdgeInsets.all(20),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(headerIcon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financial Health Status',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                            ),
                            Text(
                              grade,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ── Financial Analysis & How to Recover Section ────────────────
            recoveryAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, _) => const SizedBox.shrink(),
              data: (analysis) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: Color(0xFF0284C7), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Financial Analysis & Recovery Plan 💡',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ModernCard(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary Message
                          Text(
                            analysis.summaryMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                              height: 1.4,
                            ),
                          ),
                          const Divider(height: 24),

                          // Root Causes Analysis
                          const Text(
                            'ROOT CAUSE ANALYSIS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          for (final cause in analysis.rootCauses) ...[
                            _RootCauseTile(cause: cause, isDark: isDark),
                            const SizedBox(height: 8),
                          ],

                          const Divider(height: 24),

                          // Recommended Daily Spend Limit & Recovery Plan
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFF0284C7).withValues(alpha: 0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Daily Spend Limit',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '₱${analysis.recommendedDailySpendLimit.toStringAsFixed(0)} / day',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.extrabold, color: Color(0xFF0284C7)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Pacing limit for the remaining ${analysis.daysRemainingInMonth} days of this month.',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                                ),
                              ),
                            ],
                          ),

                          if (analysis.estimatedRecoveryDate != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.event_available_outlined, size: 16, color: Color(0xFF10B981)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Estimated Full Recovery: ${analysis.estimatedRecoveryDate}',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),
                          const Text(
                            'ACTIONABLE RECOVERY STEPS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          for (final step in analysis.actionSteps) ...[
                            _ActionStepTile(step: step, isDark: isDark),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // ── Active Predictive Insights List ─────────────────────────────
            Text(
              'Active Predictive Insights',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            alertsAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading alerts: $err'),
              ),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return ModernCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          size: 40,
                          color: AppColors.emerald500.withValues(alpha: 0.8),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No unread alerts — your baseline predictions are updated.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ModernCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < alerts.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        _AlertTile(alert: alerts[i], isDark: isDark),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RootCauseTile extends StatelessWidget {
  final RootCauseItem cause;
  final bool isDark;

  const _RootCauseTile({required this.cause, required this.isDark});

  @override
  Widget build(BuildContext context) {
    Color tagColor;
    if (cause.severity == 'critical') {
      tagColor = const Color(0xFFEF4444);
    } else if (cause.severity == 'warning') {
      tagColor = const Color(0xFFF59E0B);
    } else {
      tagColor = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tagColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tagColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: tagColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cause.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cause.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionStepTile extends StatelessWidget {
  final ActionStepItem step;
  final bool isDark;

  const _ActionStepTile({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  final AlertItem alert;
  final bool isDark;

  const _AlertTile({required this.alert, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    switch (alert.type) {
      case 'budget_overrun':
        icon = Icons.pie_chart_outline;
      case 'low_balance':
        icon = Icons.account_balance_wallet_outlined;
      case 'savings_goal':
        icon = Icons.savings_outlined;
      case 'bill_due':
        icon = Icons.receipt_long_outlined;
      case 'month_end':
        icon = Icons.auto_graph;
      default:
        icon = Icons.info_outline;
    }

    final Color color;
    switch (alert.severity) {
      case 'critical':
        color = const Color(0xFFEF4444);
      case 'warning':
        color = const Color(0xFFF59E0B);
      case 'info':
        color = const Color(0xFF3B82F6);
      default:
        color = const Color(0xFF64748B);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  alert.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _timeAgo(alert.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDark
                        ? AppColors.textMuted.withValues(alpha: 0.7)
                        : AppColors.textMutedL.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }
}
