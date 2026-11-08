import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/preference_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/offline_status.dart';
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
    final userProfileAsync = ref.watch(userProfileProvider);
    final billsAsync = ref.watch(billsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final accountBalancesAsync = ref.watch(accountBalancesProvider);
    final excludedAccountIds = ref.watch(excludedAccountsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    final userProfile = userProfileAsync.valueOrNull;
    final bills = billsAsync.valueOrNull ?? [];
    final goals = goalsAsync.valueOrNull ?? [];
    final hasInputError =
        billsAsync.hasError || goalsAsync.hasError || userProfileAsync.hasError;

    final topPadding = math.max(56.0, MediaQuery.paddingOf(context).top + 16.0);

    return Scaffold(
      backgroundColor: context.kColors.canvas,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: context.kColors.canvas,
          gradient: context.kColors.backgroundGradient,
        ),
        child: RefreshIndicator(
          color: context.kColors.textPrimary,
          backgroundColor: context.kColors.card,
          onRefresh: () async {
            ref.invalidate(planningProvider);
            ref.invalidate(dashboardProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              topPadding,
              20,
              DashboardTokens.dockClearance,
            ),
            children: [
              // ── 1. Page Header (Node 92:38) ────────────────────────
              _ForecastingHeader(
                onForecastIconTap: () {
                  AppHaptics.selectionClick();
                  final totalBalance =
                      dashboardAsync.valueOrNull?.totalBalance ?? 0.0;
                  final calc = calculateDailySafeSpend(
                    totalLiquidBalance: adjustedLiquidBalance(
                      dashboardTotalBalance: totalBalance,
                      accountBalances: accountBalancesAsync.valueOrNull,
                      excludedAccountIds: excludedAccountIds,
                    ),
                    bills: bills,
                    goals: goals,
                    profile: userProfile,
                  );
                  showSafeSpendBreakdownSheet(context, calc);
                },
              ),
              const SizedBox(height: 24),

              if (!isOnline) ...[
                const NeedsInternetNotice(
                  message:
                      'Planning, health score, and forecasts need a connection.',
                ),
                const SizedBox(height: 16),
              ],

              // ── 2. Safe to Spend Today Hero Card (Node 85:1085) ────
              dashboardAsync.when(
                loading: () => const _HeroLoadingState(),
                error: (err, _) => isOnline
                    ? _ErrorCard(
                        message: friendlyErrorMessage(err),
                        onRetry: () => ref.invalidate(dashboardProvider),
                      )
                    : const SizedBox.shrink(),
                data: (dashboard) {
                  final adjustedBalance = adjustedLiquidBalance(
                    dashboardTotalBalance: dashboard.totalBalance,
                    accountBalances: accountBalancesAsync.valueOrNull,
                    excludedAccountIds: excludedAccountIds,
                  );
                  final safeSpendCalc = calculateDailySafeSpend(
                    totalLiquidBalance: adjustedBalance,
                    bills: bills,
                    goals: goals,
                    profile: userProfile,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasInputError) ...[
                        if (isOnline)
                          KasyabaErrorCard(
                            message:
                                'Could not load your bills, goals, or profile. Safe-to-spend and allocation are hidden until all inputs load.',
                            onRetry: () {
                              ref.invalidate(billsProvider);
                              ref.invalidate(goalsProvider);
                              ref.invalidate(userProfileProvider);
                            },
                          ),
                        const SizedBox(height: 16),
                      ] else ...[
                        FadeSlideEntrance.staggered(
                          index: 0,
                          child: _SafeSpendHeroCard(
                            safeSpendCalc: safeSpendCalc,
                            totalBalance: adjustedBalance,
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
                          child: _AllocationCard(safeSpendCalc: safeSpendCalc),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── 4. Assumptions Card (Node 92:106) ────────────
                      planningAsync.when(
                        loading: () => const KasyabaLoadingSkeleton(lines: 3),
                        error: (err, _) => isOnline
                            ? KasyabaErrorCard(
                                message: friendlyErrorMessage(err),
                                onRetry: () => ref.invalidate(planningProvider),
                              )
                            : const SizedBox.shrink(),
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
                  color: context.kColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Simulate any purchase before you spend. Evaluates bill conflicts, cash buffer, and savings goal delays.',
                style: GoogleFonts.dmSans(
                  color: context.kColors.textSecondary,
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
              color: context.kColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.kColors.cardBorder, width: 1),
            ),
            child: SvgPicture.asset(
              'assets/images/forecast_icon.svg',
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                context.kColors.textPrimary,
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
    final paydayDateStr = DateFormat('MMM d').format(safeSpendCalc.nextPayday);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: context.kColors.cardHero,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: context.kColors.cardBorderStrong,
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
                  color: context.kColors.textSecondary,
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
                    color: context.kColors.textPrimary,
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
                  color: context.kColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 14),

              // Divider
              Container(height: 1, color: context.kColors.cardBorder),
              const SizedBox(height: 12),

              // Total balance row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total balance',
                    style: GoogleFonts.dmSans(
                      color: context.kColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(totalBalance),
                    style: GoogleFonts.dmSans(
                      color: context.kColors.textPrimary,
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
                      color: context.kColors.primaryButton,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Test a purchase',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.kColors.onPrimaryButton,
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

  const _AllocationCard({required this.safeSpendCalc});

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

    final hasProportions = sum > 0;
    final freePct = hasProportions ? ((freeCash / sum) * 100).round() : 0;
    final goalsPct = hasProportions ? ((goalsCash / sum) * 100).round() : 0;
    final billsPct = hasProportions ? math.max(0, 100 - freePct - goalsPct) : 0;

    return Container(
      decoration: BoxDecoration(
        color: context.kColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.kColors.cardBorder, width: 1),
      ),
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'WHERE TODAY’S $titleSpendStr GOES',
            style: GoogleFonts.dmSans(
              color: context.kColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 14),

          if (hasProportions) ...[
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
                          color: context.kColors.accentViolet,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      flex: math.max(1, goalsPct),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.kColors.accentTeal,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Expanded(
                      flex: math.max(1, billsPct),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.kColors.warning,
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
                  color: context.kColors.accentViolet,
                  label: 'Free $freePct%',
                ),
                const SizedBox(width: 14),
                _LegendItem(
                  color: context.kColors.accentTeal,
                  label: 'Goals $goalsPct%',
                ),
                const SizedBox(width: 14),
                _LegendItem(
                  color: context.kColors.warning,
                  label: 'Bills $billsPct%',
                ),
              ],
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.kColors.canvas.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.kColors.cardBorder),
              ),
              child: Text(
                'No allocation data yet. Add unpaid bills or active goals to see where your money goes.',
                style: GoogleFonts.dmSans(
                  color: context.kColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
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
            color: context.kColors.textMuted,
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
        color: context.kColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.kColors.cardBorder, width: 1),
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
                              color: context.kColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$plannedCount scheduled in window · ${CurrencyFormatter.format(totalPlannedOut)} planned out',
                            style: GoogleFonts.dmSans(
                              color: context.kColors.textMuted,
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
                        colorFilter: ColorFilter.mode(
                          context.kColors.textMuted,
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
            Divider(color: context.kColors.cardBorder, height: 1),
            const SizedBox(height: 10),
            for (final day in overview.days.where(
              (d) => d.expenses > 0 || d.bills > 0 || d.income > 0,
            )) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM d, E').format(day.date),
                      style: GoogleFonts.dmSans(
                        color: context.kColors.textSecondary,
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
                            ? context.kColors.success
                            : context.kColors.textPrimary,
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
        color: context.kColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: context.kColors.cardBorder),
      ),
      child: Center(
        child: CircularProgressIndicator(color: context.kColors.textPrimary),
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
        color: context.kColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: context.kColors.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          Text(
            message,
            style: GoogleFonts.dmSans(
              color: context.kColors.danger,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(
              Icons.refresh,
              size: 16,
              color: context.kColors.textPrimary,
            ),
            label: Text(
              'Retry',
              style: GoogleFonts.dmSans(
                color: context.kColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
