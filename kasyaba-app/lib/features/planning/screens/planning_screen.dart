import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_card.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  bool _showAllDays = false;

  void _showScenarioLab(BuildContext context, PlanningOverview overview) {
    ModernBottomSheet.show(
      context: context,
      title: 'What-If Simulator',
      subtitle: 'Test a purchase or windfall without saving any changes.',
      child: _WhatIfSimulatorSheet(overview: overview),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planningAsync = ref.watch(planningProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        title: const Text('Daily Allowance & Runway'),
        actions: [
          IconButton(
            tooltip: 'Refresh plan',
            onPressed: () => ref.invalidate(planningProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: planningAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.emerald500),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expense,
                    size: 34,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Could not load your plan',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    friendlyErrorMessage(
                      error,
                      fallback: 'Something went wrong while loading your plan.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(planningProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (overview) {
          final milestoneEntries = _buildMilestoneEntries(overview.days);
          final activeEventsCount = overview.days.where((d) {
            return d.income > 0 ||
                d.expenses > 0 ||
                d.bills > 0 ||
                d.pressure != 'clear';
          }).length;

          return RefreshIndicator(
            color: AppColors.emerald500,
            onRefresh: () async {
              ref.invalidate(planningProvider);
              await ref.read(planningProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _PlanningHero(
                  overview: overview,
                  onScenarioTap: () => _showScenarioLab(context, overview),
                ),
                const SizedBox(height: 14),
                _PlanningMetricRow(overview: overview),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash-Flow Runway',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${DateFormat('MMM d').format(overview.from)} – ${DateFormat('MMM d').format(overview.to)} • ${overview.daysInWindow} days',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TimelineToggle(
                      showAllDays: _showAllDays,
                      milestoneCount: activeEventsCount,
                      totalDays: overview.days.length,
                      onToggle: (allDays) {
                        setState(() => _showAllDays = allDays);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!_showAllDays) ...[
                  if (activeEventsCount == 0)
                    _EmptyRunwayCard(
                      currentBalance: overview.currentBalance,
                      daysInWindow: overview.daysInWindow,
                    )
                  else
                    ...milestoneEntries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: switch (entry) {
                          _MilestoneEntry e => _PlanningDayTile(
                              day: e.day,
                              isMilestone: true,
                            ),
                          _QuietSpanEntry s => _QuietSpanTile(span: s),
                        },
                      );
                    }),
                ] else ...[
                  ...overview.days.map((day) {
                    final isAct = day.income > 0 ||
                        day.expenses > 0 ||
                        day.bills > 0 ||
                        day.pressure != 'clear';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _PlanningDayTile(
                        day: day,
                        isMilestone: isAct,
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 12),
                ModernCard(
                  backgroundColor: AppColors.surface900,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.calculate_outlined,
                        color: AppColors.gold400,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOW THIS IS CALCULATED',
                              style: TextStyle(
                                color: AppColors.gold400,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              overview.calculationNote,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ],
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Timeline Entries for Milestones vs Quiet Periods
// ─────────────────────────────────────────────────────────────
sealed class _TimelineEntry {}

class _MilestoneEntry extends _TimelineEntry {
  final PlanningDay day;
  _MilestoneEntry(this.day);
}

class _QuietSpanEntry extends _TimelineEntry {
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final double balance;

  _QuietSpanEntry({
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.balance,
  });
}

List<_TimelineEntry> _buildMilestoneEntries(List<PlanningDay> days) {
  final result = <_TimelineEntry>[];
  final quietBuffer = <PlanningDay>[];

  void flushQuiet() {
    if (quietBuffer.isEmpty) return;
    if (quietBuffer.length == 1) {
      result.add(_MilestoneEntry(quietBuffer.first));
    } else {
      result.add(_QuietSpanEntry(
        startDate: quietBuffer.first.date,
        endDate: quietBuffer.last.date,
        daysCount: quietBuffer.length,
        balance: quietBuffer.last.projectedBalance,
      ));
    }
    quietBuffer.clear();
  }

  for (final day in days) {
    final hasActivity = day.income > 0 ||
        day.expenses > 0 ||
        day.bills > 0 ||
        day.pressure == 'risk' ||
        day.pressure == 'watch';
    if (hasActivity) {
      flushQuiet();
      result.add(_MilestoneEntry(day));
    } else {
      quietBuffer.add(day);
    }
  }
  flushQuiet();
  return result;
}

// ─────────────────────────────────────────────────────────────
// Timeline Toggle Pill Switcher
// ─────────────────────────────────────────────────────────────
class _TimelineToggle extends StatelessWidget {
  final bool showAllDays;
  final int milestoneCount;
  final int totalDays;
  final ValueChanged<bool> onToggle;

  const _TimelineToggle({
    required this.showAllDays,
    required this.milestoneCount,
    required this.totalDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surface600.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            label: 'Milestones ($milestoneCount)',
            isSelected: !showAllDays,
            onTap: () => onToggle(false),
          ),
          _buildPill(
            label: 'All ($totalDays)',
            isSelected: showAllDays,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface600 : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0x55D4AF37), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.textDark : AppColors.textMuted,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Empty Runway Card (when no bills exist)
// ─────────────────────────────────────────────────────────────
class _EmptyRunwayCard extends StatelessWidget {
  final double currentBalance;
  final int daysInWindow;

  const _EmptyRunwayCard({
    required this.currentBalance,
    required this.daysInWindow,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: AppColors.surface800,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.emerald500.withValues(alpha: 0.3),
              ),
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.emerald400,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'No Bills in this Runway',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No bills or scheduled outflows for the next $daysInWindow days. Your full ${_money(currentBalance)} is unencumbered for daily spending.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
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

// ─────────────────────────────────────────────────────────────
// Quiet Span Tile (Groups inactive days into a single calm tile)
// ─────────────────────────────────────────────────────────────
class _QuietSpanTile extends StatelessWidget {
  final _QuietSpanEntry span;

  const _QuietSpanTile({required this.span});

  @override
  Widget build(BuildContext context) {
    final startFormatted = DateFormat('MMM d').format(span.startDate);
    final endFormatted = DateFormat('MMM d').format(span.endDate);

    return ModernCard(
      backgroundColor: AppColors.surface800.withValues(alpha: 0.5),
      borderColor: AppColors.surface700.withValues(alpha: 0.6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surface700.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.textMuted,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$startFormatted – $endFormatted',
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface700,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${span.daysCount} quiet days',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                const Text(
                  'No scheduled bills • Balance holds steady',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(span.balance),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  fontFeatures: CurrencyFormatter.tabularFigures,
                ),
              ),
              const Text(
                'holding',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Planning Hero Card (Human-First Narrative + Daily Safe-to-Spend)
// ─────────────────────────────────────────────────────────────
class _PlanningHero extends StatelessWidget {
  final PlanningOverview overview;
  final VoidCallback onScenarioTap;

  const _PlanningHero({
    required this.overview,
    required this.onScenarioTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(overview.status);
    final toFormatted = DateFormat('MMMM d').format(overview.to);

    return ModernCard(
      gradient: AppColors.gradientHeroCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.gold400,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold400.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DAILY SPENDING ALLOWANCE',
                    style: TextStyle(
                      color: AppColors.gold400,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _statusLabel(overview.status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _money(overview.safeToSpendPerDay),
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
          Text(
            'safe to spend per day for the next ${overview.daysInWindow} days',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // ── Human narrative bridge container ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface700.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.surface600.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.gold400,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 12,
                        height: 1.45,
                      ),
                      children: [
                        const TextSpan(text: 'Starting from '),
                        TextSpan(
                          text: _money(overview.currentBalance),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (overview.committedOutflow > 0) ...[
                          const TextSpan(text: ', reserving '),
                          TextSpan(
                            text: '-${_money(overview.committedOutflow)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.expense,
                            ),
                          ),
                          const TextSpan(text: ' for bills'),
                        ],
                        if (overview.totalPlannedIncome > 0) ...[
                          const TextSpan(text: ' and adding '),
                          TextSpan(
                            text: '+${_money(overview.totalPlannedIncome)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.income,
                            ),
                          ),
                          const TextSpan(text: ' expected income'),
                        ],
                        const TextSpan(text: ', you have '),
                        TextSpan(
                          text: _money(overview.projectedClosingBalance),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald400,
                          ),
                        ),
                        TextSpan(
                          text: ' free for daily living until $toFormatted.',
                        ),
                        if (overview.minimumBalanceThreshold > 0)
                          TextSpan(
                            text:
                                '\n(Safety cushion of ${_money(overview.minimumBalanceThreshold)} stays untouched).',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onScenarioTap,
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Simulate a "What-If" Purchase'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold300,
                side: BorderSide(
                  color: AppColors.gold500.withValues(alpha: 0.5),
                  width: 1,
                ),
                backgroundColor: AppColors.gold500.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3 High-Signal Metric Cards
// ─────────────────────────────────────────────────────────────
class _PlanningMetricRow extends StatelessWidget {
  final PlanningOverview overview;

  const _PlanningMetricRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    final toFormatted = DateFormat('MMM d').format(overview.to);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _PlanningMetric(
                label: 'Current Cash',
                sublabel: 'In Wallets',
                value: _money(overview.currentBalance),
                color: AppColors.textDark,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PlanningMetric(
                label: 'Due for Bills',
                sublabel: 'Reserved',
                value: overview.committedOutflow > 0
                    ? '-${_money(overview.committedOutflow)}'
                    : '₱0.00',
                color: overview.committedOutflow > 0
                    ? AppColors.expense
                    : AppColors.textMuted,
                icon: Icons.receipt_long_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PlanningMetric(
                label: 'Free to Spend',
                sublabel: 'Until $toFormatted',
                value: _money(overview.projectedClosingBalance),
                color: AppColors.emerald400,
                icon: Icons.check_circle_outline_rounded,
              ),
            ),
          ],
        ),
        if (overview.totalPlannedIncome > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.income.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.income,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '+${_money(overview.totalPlannedIncome)} planned income factored into this window',
                    style: const TextStyle(
                      color: AppColors.income,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PlanningMetric extends StatelessWidget {
  final String label;
  final String sublabel;
  final String value;
  final Color color;
  final IconData icon;

  const _PlanningMetric({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: AppColors.surface800,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(icon, color: AppColors.textMuted, size: 14),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 13,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Enhanced Planning Day Tile (Active Bill / Milestone Highlight)
// ─────────────────────────────────────────────────────────────
class _PlanningDayTile extends StatelessWidget {
  final PlanningDay day;
  final bool isMilestone;

  const _PlanningDayTile({
    required this.day,
    this.isMilestone = false,
  });

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(day.pressure);
    final isToday = _isToday(day.date);

    final eventWidgets = <Widget>[];
    if (day.bills > 0) {
      eventWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.expense,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              '-${_money(day.bills)} bills due',
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    if (day.expenses > 0) {
      eventWidgets.add(
        Text(
          '-${_money(day.expenses)} planned',
          style: const TextStyle(
            color: AppColors.expense,
            fontSize: 11,
          ),
        ),
      );
    }
    if (day.income > 0) {
      eventWidgets.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_downward_rounded,
              color: AppColors.income,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              '+${_money(day.income)} income',
              style: const TextStyle(
                color: AppColors.income,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    if (eventWidgets.isEmpty) {
      eventWidgets.add(
        const Text(
          'No scheduled activity',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      );
    }

    return ModernCard(
      backgroundColor:
          isMilestone ? AppColors.surface800 : AppColors.surface900,
      borderColor: isMilestone && (day.bills > 0 || day.income > 0)
          ? (day.bills > 0
              ? AppColors.expense.withValues(alpha: 0.3)
              : AppColors.income.withValues(alpha: 0.3))
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: isMilestone ? color : AppColors.surface600,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'TODAY' : DateFormat('EEE').format(day.date),
                  style: TextStyle(
                    color: isToday ? AppColors.gold300 : AppColors.textMuted,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 11,
                    letterSpacing: isToday ? 0.3 : 0,
                  ),
                ),
                Text(
                  DateFormat('MMM d').format(day.date),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: eventWidgets,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(day.projectedBalance),
                style: TextStyle(
                  color: isMilestone ? color : AppColors.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  fontFeatures: CurrencyFormatter.tabularFigures,
                ),
              ),
              const Text(
                'balance',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// What-If Spending Simulator Sheet
// ─────────────────────────────────────────────────────────────
class _WhatIfSimulatorSheet extends StatefulWidget {
  final PlanningOverview overview;

  const _WhatIfSimulatorSheet({required this.overview});

  @override
  State<_WhatIfSimulatorSheet> createState() => _WhatIfSimulatorSheetState();
}

class _WhatIfSimulatorSheetState extends State<_WhatIfSimulatorSheet> {
  final _expenseController = TextEditingController();
  final _incomeController = TextEditingController();
  final _savingsController = TextEditingController();

  int _selectedPresetIndex = -1;

  @override
  void dispose() {
    _expenseController.dispose();
    _incomeController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  void _applyPreset({
    required int index,
    double? expense,
    double? income,
  }) {
    setState(() {
      _selectedPresetIndex = index;
      if (expense != null) {
        _expenseController.text = expense.toStringAsFixed(0);
      } else {
        _expenseController.clear();
      }
      if (income != null) {
        _incomeController.text = income.toStringAsFixed(0);
      } else {
        _incomeController.clear();
      }
      _savingsController.clear();
    });
  }

  void _reset() {
    setState(() {
      _selectedPresetIndex = -1;
      _expenseController.clear();
      _incomeController.clear();
      _savingsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    double readAmount(TextEditingController controller) {
      return double.tryParse(controller.text.trim()) ?? 0.0;
    }

    final addedExpense = readAmount(_expenseController);
    final addedIncome = readAmount(_incomeController);
    final addedSavings = readAmount(_savingsController);

    final simulatedClosing = widget.overview.projectedClosingBalance +
        addedIncome -
        addedExpense -
        addedSavings;
    final simulatedBuffer =
        simulatedClosing - widget.overview.minimumBalanceThreshold;
    final simulatedDaily =
        simulatedBuffer > 0 && widget.overview.daysInWindow > 0
            ? simulatedBuffer / widget.overview.daysInWindow
            : 0.0;

    final dailyDelta = simulatedDaily - widget.overview.safeToSpendPerDay;
    final closingDelta =
        simulatedClosing - widget.overview.projectedClosingBalance;
    final hasModifications =
        addedExpense > 0 || addedIncome > 0 || addedSavings > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Quick Presets ──
        const Text(
          'QUICK PRESETS',
          style: TextStyle(
            color: AppColors.gold400,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetChip(
                label: 'Dinner (-₱1.5k)',
                isSelected: _selectedPresetIndex == 0,
                onTap: () => _applyPreset(index: 0, expense: 1500),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: 'Shopping (-₱5k)',
                isSelected: _selectedPresetIndex == 1,
                onTap: () => _applyPreset(index: 1, expense: 5000),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: 'Gadget (-₱15k)',
                isSelected: _selectedPresetIndex == 2,
                onTap: () => _applyPreset(index: 2, expense: 15000),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: 'Bonus (+₱10k)',
                isSelected: _selectedPresetIndex == 3,
                onTap: () => _applyPreset(index: 3, income: 10000),
              ),
              const SizedBox(width: 8),
              _PresetChip(
                label: 'Reset',
                isSelected: false,
                isReset: true,
                onTap: _reset,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── Input Fields ──
        _ScenarioAmountField(
          controller: _expenseController,
          label: 'One-time extra expense (e.g. big buy)',
          icon: Icons.remove_circle_outline_rounded,
          color: AppColors.expense,
          onChanged: (_) => setState(() => _selectedPresetIndex = -1),
        ),
        const SizedBox(height: 12),
        _ScenarioAmountField(
          controller: _incomeController,
          label: 'One-time windfall or side income',
          icon: Icons.add_circle_outline_rounded,
          color: AppColors.income,
          onChanged: (_) => setState(() => _selectedPresetIndex = -1),
        ),
        const SizedBox(height: 12),
        _ScenarioAmountField(
          controller: _savingsController,
          label: 'Extra savings to lock away',
          icon: Icons.savings_outlined,
          color: AppColors.info,
          onChanged: (_) => setState(() => _selectedPresetIndex = -1),
        ),
        const SizedBox(height: 20),

        // ── Real-time Simulated Outcome Card ──
        ModernCard(
          backgroundColor: AppColors.surface700,
          borderColor: simulatedBuffer < 0
              ? AppColors.expense.withValues(alpha: 0.5)
              : const Color(0x44D4AF37),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SIMULATED IMPACT',
                    style: TextStyle(
                      color: AppColors.gold400,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  if (hasModifications)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: (simulatedBuffer < 0
                                ? AppColors.expense
                                : AppColors.emerald500)
                            .withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        simulatedBuffer < 0 ? 'DEFICIT RISK' : 'FEASIBLE',
                        style: TextStyle(
                          color: simulatedBuffer < 0
                              ? AppColors.expense
                              : AppColors.emerald400,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'New Daily Allowance',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _money(simulatedDaily),
                          style: TextStyle(
                            color: simulatedDaily > 0
                                ? AppColors.emerald400
                                : AppColors.expense,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasModifications
                              ? (dailyDelta < -0.01
                                  ? '-${_money(dailyDelta.abs())}/day'
                                  : dailyDelta > 0.01
                                      ? '+${_money(dailyDelta)}/day'
                                      : 'No change')
                              : 'current: ${_money(widget.overview.safeToSpendPerDay)}/day',
                          style: TextStyle(
                            color: dailyDelta < -0.01
                                ? AppColors.expense
                                : dailyDelta > 0.01
                                    ? AppColors.income
                                    : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: AppColors.surface600.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Projected Close',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _money(simulatedClosing),
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasModifications
                              ? (closingDelta < -0.01
                                  ? '-${_money(closingDelta.abs())}'
                                  : closingDelta > 0.01
                                      ? '+${_money(closingDelta)}'
                                      : 'No change')
                              : 'at window end',
                          style: TextStyle(
                            color: closingDelta < -0.01
                                ? AppColors.expense
                                : closingDelta > 0.01
                                    ? AppColors.income
                                    : AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // ── Plain-English Verdict ──
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (simulatedBuffer < 0
                          ? AppColors.expense
                          : hasModifications
                              ? AppColors.emerald500
                              : AppColors.surface800)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (simulatedBuffer < 0
                            ? AppColors.expense
                            : hasModifications
                                ? AppColors.emerald500
                                : AppColors.surface600)
                        .withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      simulatedBuffer < 0
                          ? Icons.warning_amber_rounded
                          : hasModifications
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                      color: simulatedBuffer < 0
                          ? AppColors.expense
                          : hasModifications
                              ? AppColors.emerald400
                              : AppColors.textMuted,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        simulatedBuffer < 0
                            ? 'Warning: This purchase breaks your budget by ${_money(simulatedBuffer.abs())}. You will run out of funds before the window ends.'
                            : hasModifications
                                ? 'Safe! You can afford this. Your daily allowance will adjust to ${_money(simulatedDaily)}/day.'
                                : 'Type an amount or tap a preset above to test how a decision alters your daily allowance. Nothing is saved.',
                        style: TextStyle(
                          color: simulatedBuffer < 0
                              ? AppColors.expense
                              : hasModifications
                                  ? AppColors.emerald400
                                  : AppColors.textMuted,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Preset Chip Widget
// ─────────────────────────────────────────────────────────────
class _PresetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isReset;
  final VoidCallback onTap;

  const _PresetChip({
    required this.label,
    required this.isSelected,
    this.isReset = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: () {
        AppHaptics.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.emerald500.withValues(alpha: isDark ? 0.2 : 0.12)
              : isReset
                  ? (isDark ? AppColors.surface700 : AppColors.lightInputFill)
                  : (isDark ? AppColors.surface800 : AppColors.lightInputFill),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.emerald500
                : (isDark
                    ? AppColors.surface600.withValues(alpha: 0.5)
                    : AppColors.lightBorderHairline),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? AppColors.emerald500
                : isReset
                    ? (isDark ? AppColors.textMuted : AppColors.textMutedL)
                    : (isDark ? AppColors.textDark : AppColors.textLight),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Scenario Amount Input Field
// ─────────────────────────────────────────────────────────────
class _ScenarioAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  const _ScenarioAmountField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color, size: 20),
        prefixText: '₱ ',
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Helper Utilities
// ─────────────────────────────────────────────────────────────
Color _statusColor(String status) {
  return switch (status) {
    'risk' => AppColors.expense,
    'watch' => AppColors.warning,
    _ => AppColors.emerald400,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'risk' => 'AT RISK',
    'watch' => 'WATCH',
    _ => 'ON TRACK',
  };
}

String _money(double value) => CurrencyFormatter.format(value);
