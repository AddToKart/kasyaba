import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../dashboard/widgets/kasyaba_affordability_sheet.dart';
import '../../dashboard/widgets/kasyaba_safe_spend_breakdown_sheet.dart';

/// ─────────────────────────────────────────────────────────────
///  Affordability Forecasting Screen — 1:1 Pixel-Perfect Figma (Node 85:110)
/// ─────────────────────────────────────────────────────────────
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  bool _isAssumptionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final planningAsync = ref.watch(planningProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final bills = ref.watch(billsProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];

    final topPadding =
        math.max(56.0, MediaQuery.of(context).padding.top + 16.0);

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
            ref.invalidate(planningProvider);
            ref.invalidate(dashboardProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, topPadding, 20, 110),
            children: [
              // ── 1. Page Header (Node 92:38) ────────────────────────
              _ForecastingHeader(
                onForecastIconTap: () {
                  AppHaptics.selectionClick();
                  final totalBalance =
                      dashboardAsync.valueOrNull?.totalBalance ?? 0.0;
                  final calc = calculateDailySafeSpend(
                    totalLiquidBalance: totalBalance,
                    bills: bills,
                    goals: goals,
                    profile: userProfile,
                  );
                  showSafeSpendBreakdownSheet(context, calc);
                },
              ),
              const SizedBox(height: 24),

              // ── 2. Safe to Spend Today Hero Card (Node 85:1085) ────
              dashboardAsync.when(
                loading: () => const _HeroLoadingState(),
                error: (err, _) => _ErrorCard(
                  message: friendlyErrorMessage(err),
                  onRetry: () => ref.invalidate(dashboardProvider),
                ),
                data: (dashboard) {
                  final safeSpendCalc = calculateDailySafeSpend(
                    totalLiquidBalance: dashboard.totalBalance,
                    bills: bills,
                    goals: goals,
                    profile: userProfile,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FadeSlideEntrance.staggered(
                        index: 0,
                        child: _SafeSpendHeroCard(
                          safeSpendCalc: safeSpendCalc,
                          totalBalance: dashboard.totalBalance,
                          onTestPurchaseTap: () {
                            AppHaptics.selectionClick();
                            showKasyaBaAffordabilitySheet(context);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── 3. Allocation Card (Node 92:57) ──────────────
                      FadeSlideEntrance.staggered(
                        index: 1,
                        child: _AllocationCard(
                          safeSpendCalc: safeSpendCalc,
                          totalBalance: dashboard.totalBalance,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── 4. Assumptions Card (Node 92:106) ────────────
                      planningAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (overview) {
                          return FadeSlideEntrance.staggered(
                            index: 2,
                            child: _AssumptionsCard(
                              overview: overview,
                              isExpanded: _isAssumptionsExpanded,
                              onToggleExpand: () {
                                AppHaptics.selectionClick();
                                setState(() {
                                  _isAssumptionsExpanded =
                                      !_isAssumptionsExpanded;
                                });
                              },
                            ),
                          );
                        },
                      ),
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
}

/// ── 1. Page Header (Node 92:38) ─────────────────────────────────────────
class _ForecastingHeader extends StatelessWidget {
  final VoidCallback onForecastIconTap;

  const _ForecastingHeader({required this.onForecastIconTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Block
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Affordability Forecasting',
                style: GoogleFonts.bricolageGrotesque(
                  color: DashboardTokens.periwinkleGray,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Simulate any purchase before you spend. Evaluates bill conflicts, cash buffer, and savings goal delays.',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGraySubtitle,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Forecast / Math Breakdown Icon Button (44×44, r=24)
        GestureDetector(
          onTap: onForecastIconTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DashboardTokens.bigStone,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: DashboardTokens.poloBlue22,
                width: 1,
              ),
            ),
            child: SvgPicture.asset(
              'assets/images/forecast_icon.svg',
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(
                DashboardTokens.periwinkleGray,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ── 2. Safe to Spend Hero Card (Node 85:1085) ───────────────────────────
class _SafeSpendHeroCard extends StatelessWidget {
  final DailySafeSpendCalculation safeSpendCalc;
  final double totalBalance;
  final VoidCallback onTestPurchaseTap;

  const _SafeSpendHeroCard({
    required this.safeSpendCalc,
    required this.totalBalance,
    required this.onTestPurchaseTap,
  });

  @override
  Widget build(BuildContext context) {
    final paydayDateStr =
        DateFormat('MMM d').format(safeSpendCalc.nextPayday);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: DashboardTokens.cello60,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: DashboardTokens.poloBlue30,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label: SAFE TO SPEND TODAY
              Text(
                'SAFE TO SPEND TODAY',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGraySubtitle,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 6),

              // Large Amount (44px)
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  CurrencyFormatter.format(safeSpendCalc.dailySafeSpend),
                  style: GoogleFonts.bricolageGrotesque(
                    color: DashboardTokens.periwinkleGray,
                    fontSize: 44,
                    height: 46.2 / 44,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Payday horizon
              Text(
                'For the next ${safeSpendCalc.daysUntilPayday} days, until $paydayDateStr payday',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGraySubtitle,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),

              // Divider
              Container(
                height: 1,
                color: DashboardTokens.poloBlue22,
              ),
              const SizedBox(height: 12),

              // Total balance row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total balance',
                    style: GoogleFonts.dmSans(
                      color: DashboardTokens.periwinkleGraySubtitle,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(totalBalance),
                    style: GoogleFonts.dmSans(
                      color: DashboardTokens.periwinkleGray,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFeatures: CurrencyFormatter.tabularFigures,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Test a purchase Button (308×56, r=28)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: SpringTouch(
                  scaleDown: 0.96,
                  onTap: onTestPurchaseTap,
                  child: Container(
                    decoration: BoxDecoration(
                      color: DashboardTokens.periwinkleGray,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Test a purchase',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.ebony,
                      ),
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

/// ── 3. Allocation Card (Node 92:57) ─────────────────────────────────────
class _AllocationCard extends StatelessWidget {
  final DailySafeSpendCalculation safeSpendCalc;
  final double totalBalance;

  const _AllocationCard({
    required this.safeSpendCalc,
    required this.totalBalance,
  });

  @override
  Widget build(BuildContext context) {
    final dailySpendRounded = safeSpendCalc.dailySafeSpend.round();
    final titleSpendStr = dailySpendRounded > 0
        ? '₱${NumberFormat('#,###').format(dailySpendRounded)}'
        : '₱0';

    // Compute dynamic proportions based on safeSpendCalc breakdown
    final freeCash = math.max(0.0, safeSpendCalc.numerator);
    final goalsCash = safeSpendCalc.scheduledGoalContributions;
    final billsCash = safeSpendCalc.unpaidBillsDue;
    final sum = freeCash + goalsCash + billsCash;

    final int freePct;
    final int goalsPct;
    final int billsPct;

    if (sum > 0) {
      freePct = ((freeCash / sum) * 100).round();
      goalsPct = ((goalsCash / sum) * 100).round();
      billsPct = math.max(0, 100 - freePct - goalsPct);
    } else {
      // Figma defaults when empty: 25%, 31%, 44%
      freePct = 25;
      goalsPct = 31;
      billsPct = 44;
    }

    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: DashboardTokens.poloBlue22,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'WHERE TODAY’S $titleSpendStr GOES',
            style: GoogleFonts.dmSans(
              color: DashboardTokens.periwinkleGraySubtitle,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          // Multi-Segment Bar (Height: 12, radius: 5, gap: 3)
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, freePct),
                    child: Container(
                      decoration: BoxDecoration(
                        color: DashboardTokens.cornflowerBlue,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: math.max(1, goalsPct),
                    child: Container(
                      decoration: BoxDecoration(
                        color: DashboardTokens.java,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: math.max(1, billsPct),
                    child: Container(
                      decoration: BoxDecoration(
                        color: DashboardTokens.casablanca,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Legend Row
          Row(
            children: [
              _LegendItem(
                color: DashboardTokens.cornflowerBlue,
                label: 'Free $freePct%',
              ),
              const SizedBox(width: 14),
              _LegendItem(
                color: DashboardTokens.java,
                label: 'Goals $goalsPct%',
              ),
              const SizedBox(width: 14),
              _LegendItem(
                color: DashboardTokens.casablanca,
                label: 'Bills $billsPct%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: DashboardTokens.baliHai,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

/// ── 4. Assumptions Card (Node 92:106) ───────────────────────────────────
class _AssumptionsCard extends StatelessWidget {
  final PlanningOverview overview;
  final bool isExpanded;
  final VoidCallback onToggleExpand;

  const _AssumptionsCard({
    required this.overview,
    required this.isExpanded,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    final plannedCount = overview.days
        .where((d) => d.expenses > 0 || d.bills > 0 || d.income > 0)
        .length;
    final totalPlannedOut =
        overview.totalPlannedExpenses + overview.totalUpcomingBills;

    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: DashboardTokens.poloBlue22,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggleExpand,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Planned transactions',
                            style: GoogleFonts.dmSans(
                              color: DashboardTokens.zircon,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$plannedCount scheduled in window · ${CurrencyFormatter.format(totalPlannedOut)} planned out',
                            style: GoogleFonts.dmSans(
                              color: DashboardTokens.baliHai,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: SvgPicture.asset(
                        'assets/images/assumptions_icon.svg',
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          DashboardTokens.baliHai,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Collapsible planned days breakdown
          if (isExpanded) ...[
            const Divider(color: DashboardTokens.poloBlue22, height: 1),
            const SizedBox(height: 10),
            for (final day in overview.days.where(
                (d) => d.expenses > 0 || d.bills > 0 || d.income > 0)) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, E').format(day.date),
                      style: GoogleFonts.dmSans(
                        color: DashboardTokens.periwinkleGraySubtitle,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      day.bills > 0
                          ? '-${CurrencyFormatter.format(day.bills)} (bills)'
                          : (day.income > 0
                              ? '+${CurrencyFormatter.format(day.income)} (income)'
                              : '-${CurrencyFormatter.format(day.expenses)}'),
                      style: GoogleFonts.dmSans(
                        color: day.income > 0
                            ? DashboardTokens.bermuda
                            : DashboardTokens.periwinkleGray,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        fontFeatures: CurrencyFormatter.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// ── Loading & Error States ──────────────────────────────────────────────
class _HeroLoadingState extends StatelessWidget {
  const _HeroLoadingState();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 272,
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DashboardTokens.poloBlue22),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: DashboardTokens.periwinkleGray,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: DashboardTokens.apricot.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: GoogleFonts.dmSans(
              color: DashboardTokens.apricot,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh,
                size: 16, color: DashboardTokens.periwinkleGray),
            label: Text(
              'Retry',
              style: GoogleFonts.dmSans(
                color: DashboardTokens.periwinkleGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
