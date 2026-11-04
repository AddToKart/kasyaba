import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/providers/preference_providers.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../widgets/dashboard_tokens.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/hero_safe_spend_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/kasyaba_affordability_card.dart';
import '../widgets/kasyaba_affordability_sheet.dart';
import '../widgets/kasyaba_safe_spend_breakdown_sheet.dart';
import '../widgets/month_end_forecast_card.dart';
import '../widgets/spending_this_month_card.dart';
import '../widgets/dashboard_more_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBalanceVisible = true;
  bool _isQuickStartDismissed = false;

  void _showBufferHealthSheet(
    BuildContext context,
    DashboardData data,
    int? runwayDays,
    double liquidBalance,
  ) {
    final now = DateTime.now();
    final dayOfMonth = now.day.clamp(1, 31);
    final expenses = data.expenses.toDouble();
    final dailyBurn = expenses > 0 ? (expenses / dayOfMonth) : 0.0;
    final healthScore = data.healthScore;

    Color healthColor(String grade) => switch (grade.toLowerCase()) {
      'excellent' => DashboardTokens.bermuda,
      'good' => DashboardTokens.bermuda,
      'fair' => DashboardTokens.poloBlue,
      'poor' => DashboardTokens.apricot,
      'needs attention' => DashboardTokens.apricot,
      _ => DashboardTokens.bermuda,
    };

    Widget buildHealthInfoRow({
      required String label,
      required String value,
      required IconData icon,
    }) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: DashboardTokens.ebony.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DashboardTokens.poloBlue22),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: DashboardTokens.bermuda),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      );
    }

    showKasyabaSheet(
      context: context,
      builder: (sheetContext) => AppSheet(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cash Buffer & Health',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: DashboardTokens.periwinkleGray,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Deterministic calculation of your liquid runway and spending capacity.',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.35,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DashboardTokens.bigStone,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: healthColor(healthScore).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: healthColor(
                            healthScore,
                          ).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(
                        Icons.shield_outlined,
                        color: healthColor(healthScore),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            runwayDays == null
                                ? 'Unknown Days Buffer'
                                : '${runwayDays >= 90 ? "90+" : runwayDays} Days Buffer',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Status: $healthScore',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: healthColor(healthScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              buildHealthInfoRow(
                label: 'Total Liquid Balance',
                value: CurrencyFormatter.format(liquidBalance),
                icon: Icons.account_balance_wallet_outlined,
              ),
              const SizedBox(height: 10),
              buildHealthInfoRow(
                label: 'Average Daily Spend',
                value: dailyBurn > 0
                    ? '${CurrencyFormatter.format(dailyBurn)} / day'
                    : 'No spending history yet',
                icon: Icons.local_fire_department_outlined,
              ),
              const SizedBox(height: 10),
              buildHealthInfoRow(
                label: 'Estimated Survival Buffer',
                value: runwayDays == null
                    ? 'Unknown without spending history'
                    : '$runwayDays days without new income',
                icon: Icons.timer_outlined,
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardTokens.ebony.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Text(
                  'Your cash buffer estimates how long your current liquid accounts can cover typical daily living costs. A buffer over 30 days is healthy, while over 90 days provides strong financial resilience.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: DashboardTokens.periwinkleGraySubtitle,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              FilledButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  context.go('/alerts');
                },
                icon: const Icon(Icons.notifications_outlined, size: 18),
                label: const Text('View Financial Alerts'),
                style: FilledButton.styleFrom(
                  backgroundColor: DashboardTokens.periwinkleGray,
                  foregroundColor: DashboardTokens.ebony,
                  textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
      ),
    );
  }

  /// Days of runway from the safe-to-spend pool (balance minus unpaid bills
  /// and scheduled goal contributions) divided by the current daily burn.
  /// Returns null when there is no spending history to derive a burn rate.
  static int? _calculateRunway(
    DailySafeSpendCalculation calc,
    double expenses,
  ) {
    final now = DateTime.now();
    final dayOfMonth = now.day.clamp(1, 31);
    final dailyBurn = expenses > 0 ? (expenses / dayOfMonth) : 0.0;
    if (dailyBurn <= 0) return null;
    final available = calc.numerator;
    if (available <= 0) return 0;
    final days = (available / dailyBurn).floor();
    return days.clamp(0, 999);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final billsAsync = ref.watch(billsProvider);
    final budgetStatusAsync = ref.watch(budgetStatusProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);
    final accountBalancesAsync = ref.watch(accountBalancesProvider);
    final excludedAccountIds = ref.watch(excludedAccountsProvider);

    final displayName = authState.displayName ?? 'User';
    final transactions = transactionsAsync.valueOrNull ?? const [];
    final dashboardData = dashboardAsync.valueOrNull;
    final isBrandNewUser =
        transactions.isEmpty &&
        (dashboardData == null ||
            (dashboardData.income == 0 && dashboardData.expenses == 0));

    final totalBalance = (dashboardData?.totalBalance ?? 0.0).toDouble();
    final adjustedBalance = adjustedLiquidBalance(
      dashboardTotalBalance: totalBalance,
      accountBalances: accountBalancesAsync.valueOrNull,
      excludedAccountIds: excludedAccountIds,
    );
    final safeSpendCalc = calculateDailySafeSpend(
      totalLiquidBalance: adjustedBalance,
      bills: billsAsync.valueOrNull ?? const [],
      goals: goalsAsync.valueOrNull ?? const [],
      profile: userProfileAsync.valueOrNull,
    );

    final runwayDays = _calculateRunway(
      safeSpendCalc,
      (dashboardData?.expenses ?? 0.0).toDouble(),
    );

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Stack(
        children: [
          // Background Gradient (radial Kashmir Blue glow at top-right)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                color: DashboardTokens.ebony,
                gradient: DashboardTokens.canvasGradient,
              ),
            ),
          ),

          // Main Refreshable Content
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: DashboardTokens.periwinkleGray,
              backgroundColor: DashboardTokens.bigStone,
              onRefresh: () async {
                await Future.wait([
                  ref.refresh(dashboardProvider.future),
                  ref.refresh(transactionsProvider.future),
                  ref.refresh(goalsProvider.future),
                  ref.refresh(billsProvider.future),
                  ref.refresh(budgetStatusProvider.future),
                  ref.refresh(userProfileProvider.future),
                ]);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Header Bar (Avatar, Greeting, Bell Squircle) ──
                    DashboardHeader(
                      displayName: displayName,
                      onNotificationsTap: () => context.go('/alerts'),
                    ),
                    const SizedBox(height: 14),

                    // ── Offline / Pending Sync Status Banner ──
                    if ((dashboardData?.isFromCache ?? false) ||
                        pendingSyncCount > 0) ...[
                      _OfflineSyncBanner(
                        isFromCache: dashboardData?.isFromCache ?? false,
                        pendingCount: pendingSyncCount,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Hero Balance Card: "Safe to spend today" ──
                    FadeSlideEntrance.staggered(
                      index: 0,
                      child: dashboardAsync.when(
                        loading: () =>
                            const _DashboardCardSkeleton(height: 220),
                        error: (e, _) => _DashboardErrorCard(
                          message: friendlyErrorMessage(e),
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                        data: (data) => HeroSafeSpendCard(
                          totalBalance: adjustedBalance,
                          safeSpendCalc: safeSpendCalc,
                          isVisible: _isBalanceVisible,
                          onToggleVisibility: () => setState(
                            () => _isBalanceVisible = !_isBalanceVisible,
                          ),
                          onExpense: () =>
                              context.go('/transactions/add', extra: 'expense'),
                          onIncome: () =>
                              context.go('/transactions/add', extra: 'income'),
                          onTapBreakdown: () => showSafeSpendBreakdownSheet(
                            context,
                            safeSpendCalc,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Quick Start Checklist (New Users) OR Deficit Alert (Existing Users) ──
                    if (dashboardAsync.hasValue &&
                        isBrandNewUser &&
                        !_isQuickStartDismissed) ...[
                      FadeSlideEntrance.staggered(
                        index: 1,
                        child: _QuickStartChecklistCard(
                          totalBalance: totalBalance,
                          income: (dashboardData?.income ?? 0.0).toDouble(),
                          salaryAmount:
                              userProfileAsync.valueOrNull?.salaryAmount,
                          paydaySchedule:
                              userProfileAsync.valueOrNull?.paydaySchedule,
                          activeGoalsCount: goalsAsync.valueOrNull?.length ?? 0,
                          activeBillsCount: billsAsync.valueOrNull?.length ?? 0,
                          onDismiss: () =>
                              setState(() => _isQuickStartDismissed = true),
                          onAddBalance: () =>
                              context.go('/transactions/add', extra: 'income'),
                          onConfigurePayday: () => context.go('/settings'),
                          onAddGoalOrBill: () => context.go('/goals'),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else if (!isBrandNewUser &&
                        safeSpendCalc.dailySafeSpend == 0.0 &&
                        safeSpendCalc.numerator < 0) ...[
                      FadeSlideEntrance.staggered(
                        index: 1,
                        child: _DeficitAlertCard(
                          deficitAmount: safeSpendCalc.numerator.abs(),
                          nextPayday: safeSpendCalc.nextPayday,
                          onAddIncome: () =>
                              context.go('/transactions/add', extra: 'income'),
                          onAdjustGoals: () => context.go('/goals'),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── 3 Metric Quick Cards (Saved, Budget used, Buffer) ──
                    FadeSlideEntrance.staggered(
                      index: 2,
                      child: dashboardAsync.when(
                        loading: () => const _DashboardCardSkeleton(height: 72),
                        error: (e, _) => KasyabaErrorCard(
                          message: friendlyErrorMessage(e),
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                        data: (data) => QuickStatsRow(
                          savings: (data.savings as num).toDouble(),
                          budgetPercent:
                              (budgetStatusAsync.valueOrNull?.overallPercent ??
                              (data.budgetUsedPercent as num).toDouble()),
                          runwayDays: runwayDays,
                          onSavedTap: () => context.go('/goals'),
                          onBudgetTap: () => context.go('/budgets'),
                          onBufferTap: () => _showBufferHealthSheet(
                            context,
                            data,
                            runwayDays,
                            adjustedBalance,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "KasyaBa?" Purchase Affordability CTA ──
                    FadeSlideEntrance.staggered(
                      index: 3,
                      child: KasyaBaAffordabilityCard(
                        onTap: () => showKasyaBaAffordabilitySheet(context),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "Month-end forecast" Card ──
                    FadeSlideEntrance.staggered(
                      index: 4,
                      child: dashboardAsync.when(
                        loading: () =>
                            const _DashboardCardSkeleton(height: 285),
                        error: (e, _) => KasyabaErrorCard(
                          message: friendlyErrorMessage(e),
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                        data: (data) => MonthEndForecastCard(
                          data: data,
                          onTap: () => context.go('/planning'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "Spending this month" Card ──
                    FadeSlideEntrance.staggered(
                      index: 5,
                      child: dashboardAsync.when(
                        loading: () =>
                            const _DashboardCardSkeleton(height: 180),
                        error: (e, _) => KasyabaErrorCard(
                          message: friendlyErrorMessage(e),
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                        data: (data) => SpendingThisMonthCard(
                          data: data,
                          onTap: () => context.go('/transactions'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "More" Hub Card (Goals, Bills, Recent Activity) ──
                    FadeSlideEntrance.staggered(
                      index: 6,
                      child: DashboardMoreCard(
                        goals: goalsAsync,
                        bills: billsAsync,
                        transactions: transactionsAsync,
                        onGoalsTap: () => context.go('/goals'),
                        onBillsTap: () => context.go('/bills'),
                        onTransactionsTap: () => context.go('/transactions'),
                        onRetryGoals: () => ref.invalidate(goalsProvider),
                        onRetryBills: () => ref.invalidate(billsProvider),
                        onRetryTransactions: () =>
                            ref.invalidate(transactionsProvider),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Offline Sync Banner ──────────────────────────────────────────

class _OfflineSyncBanner extends StatelessWidget {
  final bool isFromCache;
  final int pendingCount;

  const _OfflineSyncBanner({
    required this.isFromCache,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    final message = hasPending
        ? '$pendingCount transaction${pendingCount > 1 ? 's' : ''} saved offline • Will sync when connected'
        : 'Offline mode • Showing cached balances';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPending
              ? DashboardTokens.apricot
              : DashboardTokens.poloBlue22,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.sync_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: hasPending
                ? DashboardTokens.apricot
                : DashboardTokens.periwinkleGraySubtitle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasPending
                    ? DashboardTokens.apricot
                    : DashboardTokens.periwinkleGraySubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Start Checklist Card (New Users) ───────────────────────

class _QuickStartChecklistCard extends StatelessWidget {
  final double totalBalance;
  final double income;
  final double? salaryAmount;
  final String? paydaySchedule;
  final int activeGoalsCount;
  final int activeBillsCount;
  final VoidCallback onDismiss;
  final VoidCallback onAddBalance;
  final VoidCallback onConfigurePayday;
  final VoidCallback onAddGoalOrBill;

  const _QuickStartChecklistCard({
    required this.totalBalance,
    required this.income,
    this.salaryAmount,
    this.paydaySchedule,
    required this.activeGoalsCount,
    required this.activeBillsCount,
    required this.onDismiss,
    required this.onAddBalance,
    required this.onConfigurePayday,
    required this.onAddGoalOrBill,
  });

  @override
  Widget build(BuildContext context) {
    final step1Done = totalBalance > 0 || income > 0;
    final step2Done = salaryAmount != null && salaryAmount! > 0;
    final step3Done = activeGoalsCount > 0 || activeBillsCount > 0;
    final completedCount =
        (step1Done ? 1 : 0) + (step2Done ? 1 : 0) + (step3Done ? 1 : 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DashboardTokens.bermuda.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardTokens.ebony.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: DashboardTokens.bermuda.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DashboardTokens.bermuda.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: DashboardTokens.bermuda,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUICK SETUP GUIDE',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: DashboardTokens.bermuda,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '$completedCount of 3 completed • Set up your finances',
                      style: GoogleFonts.dmSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded, size: 18),
                color: DashboardTokens.periwinkleGraySubtitle,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Dismiss guide',
              ),
            ],
          ),
          const SizedBox(height: 14),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: completedCount / 3.0,
              backgroundColor: DashboardTokens.ebony.withValues(alpha: 0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                DashboardTokens.bermuda,
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 14),

          _buildChecklistStep(
            title: 'Log your starting balance or salary',
            subtitle: step1Done
                ? 'Recorded: ${CurrencyFormatter.format(totalBalance > 0 ? totalBalance : income)}'
                : 'Add what you have right now so your safe spend isn\'t ₱0',
            isCompleted: step1Done,
            actionLabel: step1Done ? null : '+ Add Starting Cash',
            onTap: onAddBalance,
          ),
          const SizedBox(height: 8),

          _buildChecklistStep(
            title: 'Configure salary & payday schedule',
            subtitle: step2Done
                ? '${CurrencyFormatter.format(salaryAmount!)}/mo • ${paydaySchedule ?? "15th & 30th"}'
                : 'Monthly salary not set • Defaults to 15th & 30th',
            isCompleted: step2Done,
            actionLabel: step2Done ? null : '+ Set Up',
            onTap: onConfigurePayday,
          ),
          const SizedBox(height: 8),

          _buildChecklistStep(
            title: 'Add your upcoming bills & goals',
            subtitle: step3Done
                ? '$activeGoalsCount goal${activeGoalsCount == 1 ? '' : 's'}, $activeBillsCount bill${activeBillsCount == 1 ? '' : 's'} active'
                : 'Kasyaba reserves funds so your goals are always met',
            isCompleted: step3Done,
            actionLabel: null,
            onTap: onAddGoalOrBill,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    String? actionLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCompleted
              ? DashboardTokens.poloBlue.withValues(alpha: 0.04)
              : DashboardTokens.ebony.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.transparent
                : DashboardTokens.poloBlue22,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isCompleted
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 18,
              color: isCompleted
                  ? DashboardTokens.bermuda
                  : DashboardTokens.periwinkleGraySubtitle,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DashboardTokens.bermuda.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: DashboardTokens.bermuda.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.bermuda,
                  ),
                ),
              ),
            ] else
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: DashboardTokens.periwinkleGraySubtitle,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Deficit Alert Card (Existing Users Low on Cash) ──────────────

class _DeficitAlertCard extends StatelessWidget {
  final double deficitAmount;
  final DateTime nextPayday;
  final VoidCallback onAddIncome;
  final VoidCallback onAdjustGoals;

  const _DeficitAlertCard({
    required this.deficitAmount,
    required this.nextPayday,
    required this.onAddIncome,
    required this.onAdjustGoals,
  });

  @override
  Widget build(BuildContext context) {
    final formattedPayday = DateFormat('MMM d').format(nextPayday);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DashboardTokens.apricot.withValues(alpha: 0.35),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardTokens.ebony.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DashboardTokens.apricot.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DashboardTokens.apricot.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 20,
                  color: DashboardTokens.apricot,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAY PERIOD DEFICIT',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.9,
                        color: DashboardTokens.apricot,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Safe spend paused (₱0.00/day)',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your upcoming bills and savings commitments exceed your current cash by ${CurrencyFormatter.format(deficitAmount)}. Kasyaba has paused daily spending (₱0.00/day) until your next payday on $formattedPayday to protect you from running out of funds.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: DashboardTokens.periwinkleGraySubtitle,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.mediumImpact();
                    onAddIncome();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: DashboardTokens.periwinkleGray,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: DashboardTokens.ebony,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add Income',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: DashboardTokens.ebony,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    onAdjustGoals();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: DashboardTokens.poloBlue22,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: DashboardTokens.poloBlue30,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 17,
                          color: DashboardTokens.periwinkleGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Adjust Goals',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: DashboardTokens.periwinkleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Skeletons & Errors ──────────────────────────────────────────

class _DashboardCardSkeleton extends StatelessWidget {
  final double height;

  const _DashboardCardSkeleton({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardTokens.poloBlue22),
      ),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: DashboardTokens.apricot.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: DashboardTokens.ebony.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DashboardTokens.apricot.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: DashboardTokens.apricot.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: DashboardTokens.apricot,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () {
                AppHaptics.selectionClick();
                onRetry();
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: DashboardTokens.apricot.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: DashboardTokens.apricot.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: DashboardTokens.apricot,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Retry',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.apricot,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
