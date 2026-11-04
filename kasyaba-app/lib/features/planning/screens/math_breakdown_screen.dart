import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/preference_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Math Breakdown Screen — 1:1 Carbon Copy of "How we calculate"
/// ─────────────────────────────────────────────────────────────
class MathBreakdownScreen extends ConsumerWidget {
  final DailySafeSpendCalculation? calculation;

  const MathBreakdownScreen({super.key, this.calculation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final billsAsync = ref.watch(billsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final bills = billsAsync.valueOrNull ?? [];
    final goals = goalsAsync.valueOrNull ?? [];
    final dashboard = dashboardAsync.valueOrNull;
    final accountBalances = balancesAsync.valueOrNull;
    final excludedAccountIds = ref.watch(excludedAccountsProvider);

    final calc =
        calculation ??
        calculateDailySafeSpend(
          totalLiquidBalance: adjustedLiquidBalance(
            dashboardTotalBalance: dashboard?.totalBalance ?? 0.0,
            accountBalances: accountBalances,
            excludedAccountIds: excludedAccountIds,
          ),
          bills: bills,
          goals: goals,
          profile: userProfile,
        );

    // Never present zero-based math when the live inputs failed to load.
    final hasInputFailure = calculation == null &&
        (dashboardAsync.hasError ||
            balancesAsync.hasError ||
            billsAsync.hasError ||
            goalsAsync.hasError);

    if (hasInputFailure) {
      return Scaffold(
        backgroundColor: DashboardTokens.ebony,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.go('/planning');
                    }
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: DashboardTokens.bigStone,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: DashboardTokens.poloBlue22,
                      ),
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: DashboardTokens.periwinkleGray,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'How we calculate',
                style: GoogleFonts.bricolageGrotesque(
                  color: DashboardTokens.periwinkleGray,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              KasyabaErrorCard(
                message:
                    'We could not load your live balances, bills, and goals, so this breakdown is unavailable right now.',
                onRetry: () {
                  ref.invalidate(dashboardProvider);
                  ref.invalidate(accountBalancesProvider);
                  ref.invalidate(billsProvider);
                  ref.invalidate(goalsProvider);
                  ref.invalidate(userProfileProvider);
                },
              ),
            ],
          ),
        ),
      );
    }

    final hasSafeSpend = calc.dailySafeSpend > 0;
    final accentColor = hasSafeSpend
        ? DashboardTokens.bermuda
        : DashboardTokens.apricot;

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Stack(
        children: [
          // ── Radial Glow at Top Right ──────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [KasyabaTokens.kashmirGlow35, Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Navigation Bar ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          AppHaptics.selectionClick();
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.go('/planning');
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: DashboardTokens.bigStone,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: DashboardTokens.poloBlue22,
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
                      Text(
                        'How we calculate',
                        style: GoogleFonts.bricolageGrotesque(
                          color: DashboardTokens.periwinkleGray,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable Card Content ─────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Card 1: Exact deterministic formula ─────
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _BadgeCircle(label: 'Σ'),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Exact deterministic formula',
                                    style: GoogleFonts.dmSans(
                                      color: DashboardTokens.periwinkleGray,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: DashboardTokens.ebony.withValues(
                                    alpha: 0.7,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: DashboardTokens.poloBlue22
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  'Daily Safe Spend = Math.max(0, (Total Liquid\nBalance - Unpaid Bills Due Before Next Payday\n- Scheduled Goal Contributions) / Days Until\nNext Payday)',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color:
                                        DashboardTokens.periwinkleGraySubtitle,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'In simple words:\n(Available Cash Pool) ÷ (Days Left Until Payday)',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: DashboardTokens.periwinkleGraySubtitle
                                      .withValues(alpha: 0.7),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Card 2: Find your safe cash ─────────────
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _BadgeCircle(label: '1'),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Find your safe cash',
                                    style: GoogleFonts.dmSans(
                                      color: DashboardTokens.periwinkleGray,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _BreakdownMetricRow(
                                label: 'Cash in wallets',
                                value: CurrencyFormatter.format(
                                  calc.totalLiquidBalance,
                                ),
                                valueColor: DashboardTokens.periwinkleGray,
                              ),
                              const SizedBox(height: 12),
                              _BreakdownMetricRow(
                                label: 'Unpaid bills before payday',
                                value:
                                    '- ${CurrencyFormatter.format(calc.unpaidBillsDue)}',
                                valueColor: calc.unpaidBillsDue > 0
                                    ? DashboardTokens.apricot
                                    : DashboardTokens.periwinkleGray,
                              ),
                              const SizedBox(height: 12),
                              _BreakdownMetricRow(
                                label:
                                    'Savings for ${calc.activeGoalsCount} goal${calc.activeGoalsCount == 1 ? '' : 's'}',
                                value:
                                    '- ${CurrencyFormatter.format(calc.scheduledGoalContributions)}',
                                valueColor: calc.scheduledGoalContributions > 0
                                    ? DashboardTokens.apricot
                                    : DashboardTokens.periwinkleGray,
                              ),
                              if (calc.goalDetails.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  calc.goalDetails
                                      .map((g) => g.title)
                                      .join(', '),
                                  style: GoogleFonts.dmSans(
                                    color: DashboardTokens
                                        .periwinkleGraySubtitle
                                        .withValues(alpha: 0.65),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              _BreakdownMetricRow(
                                label: 'Safe cash',
                                value: CurrencyFormatter.format(calc.numerator),
                                valueColor: DashboardTokens.periwinkleGray,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Card 3: Spread it until payday ──────────
                        _CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _BadgeCircle(label: '2'),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Spread it until payday',
                                    style: GoogleFonts.dmSans(
                                      color: DashboardTokens.periwinkleGray,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Next configured payday',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 14,
                                          color: DashboardTokens
                                              .periwinkleGraySubtitle,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Schedule: ${calc.paydaySchedule}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: DashboardTokens
                                              .periwinkleGraySubtitle
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    DateFormat(
                                      'MMMM d, yyyy',
                                    ).format(calc.nextPayday),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: DashboardTokens.periwinkleGray,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _BreakdownMetricRow(
                                label: 'Days until payday',
                                value: '÷ ${calc.daysUntilPayday} days',
                                valueColor: DashboardTokens.periwinkleGray,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Card 4: Daily Safe Spend Final Result ───
                        _CardContainer(
                          borderColor: accentColor.withValues(alpha: 0.4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DAILY SAFE SPEND',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Available to spend today',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 12.5,
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${CurrencyFormatter.format(calc.dailySafeSpend)} / day',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

// ── Reusable Component Containers & Rows ─────────────────────────────

class _CardContainer extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _CardContainer({required this.child, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? DashboardTokens.poloBlue22,
          width: 1.0,
        ),
      ),
      child: child,
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  final String label;

  const _BadgeCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: DashboardTokens.ebony.withValues(alpha: 0.6),
        shape: BoxShape.circle,
        border: Border.all(color: DashboardTokens.poloBlue22),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: DashboardTokens.poloBlue,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _BreakdownMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _BreakdownMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: isBold ? 15 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? DashboardTokens.periwinkleGray
                : DashboardTokens.periwinkleGraySubtitle,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: isBold ? 15 : 14,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFeatures: CurrencyFormatter.tabularFigures,
          ),
        ),
      ],
    );
  }
}
