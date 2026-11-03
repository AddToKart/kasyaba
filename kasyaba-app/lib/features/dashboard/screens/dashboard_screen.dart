import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_motion.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../widgets/dashboard_tokens.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/hero_safe_spend_card.dart';
import '../widgets/quick_stats_row.dart';
import '../widgets/kasyaba_affordability_card.dart';
import '../widgets/kasyaba_affordability_sheet.dart';
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

  void _showBufferHealthSheet(BuildContext context, DashboardData data, int runwayDays) {
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

    ModernBottomSheet.show(
      context: context,
      title: 'Cash Buffer & Health',
      subtitle: 'Deterministic calculation of your liquid runway and spending capacity.',
      showDragHandle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                      color: healthColor(healthScore).withValues(alpha: 0.4),
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
                        '${runwayDays >= 90 ? "90+" : runwayDays} Days Buffer',
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
            value: CurrencyFormatter.format(data.totalBalance),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 10),
          buildHealthInfoRow(
            label: 'Average Daily Spend',
            value: dailyBurn > 0
                ? '${CurrencyFormatter.format(dailyBurn)} / day'
                : '₱0.00 / day',
            icon: Icons.local_fire_department_outlined,
          ),
          const SizedBox(height: 10),
          buildHealthInfoRow(
            label: 'Estimated Survival Buffer',
            value: '$runwayDays days without new income',
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
              Navigator.of(context).pop();
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
    );
  }

  static int _calculateRunway(double balance, double expenses) {
    if (balance <= 0) return 0;
    final now = DateTime.now();
    final dayOfMonth = now.day.clamp(1, 31);
    final dailyBurn = expenses > 0 ? (expenses / dayOfMonth) : 0.0;
    if (dailyBurn <= 0) return 90;
    final days = (balance / dailyBurn).floor();
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

    final displayName = authState.displayName ?? 'User';
    final transactions = transactionsAsync.valueOrNull ?? const [];
    final dashboardData = dashboardAsync.valueOrNull;
    final isBrandNewUser = transactions.isEmpty &&
        (dashboardData == null || (dashboardData.income == 0 && dashboardData.expenses == 0));

    final totalBalance = (dashboardData?.totalBalance ?? 0.0).toDouble();
    final safeSpendCalc = calculateDailySafeSpend(
      totalLiquidBalance: totalBalance,
      bills: billsAsync.valueOrNull ?? const [],
      goals: goalsAsync.valueOrNull ?? const [],
      profile: userProfileAsync.valueOrNull,
    );

    final runwayDays = _calculateRunway(
      totalBalance,
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
                    if ((dashboardData?.isFromCache ?? false) || pendingSyncCount > 0) ...[
                      _OfflineSyncBanner(
                        isFromCache: dashboardData?.isFromCache ?? false,
                        pendingCount: pendingSyncCount,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Hero Balance Card: "Safe to spend today" ──
                    dashboardAsync.when(
                      loading: () => const _DashboardCardSkeleton(height: 220),
                      error: (e, _) => _DashboardErrorCard(
                        message: friendlyErrorMessage(e),
                        onRetry: () => ref.invalidate(dashboardProvider),
                      ),
                      data: (data) => HeroSafeSpendCard(
                        totalBalance: (data.totalBalance as num).toDouble(),
                        safeSpendCalc: safeSpendCalc,
                        isVisible: _isBalanceVisible,
                        onToggleVisibility: () => setState(
                          () => _isBalanceVisible = !_isBalanceVisible,
                        ),
                        onExpense: () =>
                            context.go('/transactions/add', extra: 'expense'),
                        onIncome: () =>
                            context.go('/transactions/add', extra: 'income'),
                        onTapBreakdown: () => _showSafeSpendBreakdownSheet(
                          context,
                          safeSpendCalc,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Quick Start Checklist (New Users) OR Deficit Alert (Existing Users) ──
                    if (dashboardAsync.hasValue && isBrandNewUser && !_isQuickStartDismissed) ...[
                      _QuickStartChecklistCard(
                        totalBalance: totalBalance,
                        income: (dashboardData?.income ?? 0.0).toDouble(),
                        salaryAmount: userProfileAsync.valueOrNull?.salaryAmount,
                        paydaySchedule: userProfileAsync.valueOrNull?.paydaySchedule,
                        activeGoalsCount: goalsAsync.valueOrNull?.length ?? 0,
                        activeBillsCount: billsAsync.valueOrNull?.length ?? 0,
                        onDismiss: () => setState(() => _isQuickStartDismissed = true),
                        onAddBalance: () => context.go('/transactions/add', extra: 'income'),
                        onConfigurePayday: () => context.go('/settings'),
                        onAddGoalOrBill: () => context.go('/goals'),
                      ),
                      const SizedBox(height: 14),
                    ] else if (!isBrandNewUser && safeSpendCalc.dailySafeSpend == 0.0 && safeSpendCalc.numerator < 0) ...[
                      _DeficitAlertCard(
                        deficitAmount: safeSpendCalc.numerator.abs(),
                        nextPayday: safeSpendCalc.nextPayday,
                        onAddIncome: () => context.go('/transactions/add', extra: 'income'),
                        onAdjustGoals: () => context.go('/goals'),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── 3 Metric Quick Cards (Saved, Budget used, Buffer) ──
                    dashboardAsync.when(
                      loading: () => const _DashboardCardSkeleton(height: 72),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (data) => QuickStatsRow(
                        savings: (data.savings as num).toDouble(),
                        budgetPercent: (budgetStatusAsync.valueOrNull?.overallPercent ??
                                (data.budgetUsedPercent as num).toDouble()),
                        runwayDays: runwayDays,
                        onSavedTap: () => context.go('/goals'),
                        onBudgetTap: () => context.go('/budgets'),
                        onBufferTap: () => _showBufferHealthSheet(context, data, runwayDays),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "KasyaBa?" Purchase Affordability CTA ──
                    KasyaBaAffordabilityCard(
                      onTap: () => showKasyaBaAffordabilitySheet(context),
                    ),
                    const SizedBox(height: 14),

                    // ── "Month-end forecast" Card ──
                    dashboardAsync.when(
                      loading: () => const _DashboardCardSkeleton(height: 285),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (data) => MonthEndForecastCard(
                        data: data,
                        onTap: () => context.go('/planning'),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "Spending this month" Card ──
                    dashboardAsync.when(
                      loading: () => const _DashboardCardSkeleton(height: 180),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (data) => SpendingThisMonthCard(
                        data: data,
                        onTap: () => context.go('/transactions'),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── "More" Hub Card (Goals, Bills, Recent Activity) ──
                    DashboardMoreCard(
                      goals: goalsAsync.valueOrNull ?? const [],
                      bills: billsAsync.valueOrNull ?? const [],
                      transactions: transactions,
                      onGoalsTap: () => context.go('/goals'),
                      onBillsTap: () => context.go('/bills'),
                      onTransactionsTap: () => context.go('/transactions'),
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
          color: hasPending ? DashboardTokens.apricot : DashboardTokens.poloBlue22,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.sync_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: hasPending ? DashboardTokens.apricot : DashboardTokens.periwinkleGraySubtitle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasPending ? DashboardTokens.apricot : DashboardTokens.periwinkleGraySubtitle,
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
              valueColor: const AlwaysStoppedAnimation<Color>(DashboardTokens.bermuda),
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
              ? Colors.white.withValues(alpha: 0.02)
              : DashboardTokens.ebony.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? Colors.transparent : DashboardTokens.poloBlue22,
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
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  const _DashboardErrorCard({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: DashboardTokens.apricot.withValues(alpha: 0.35)),
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
                    const Icon(Icons.refresh_rounded, size: 16, color: DashboardTokens.apricot),
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

// ─── Kasya Ba Today? Math Breakdown Sheet ──────────────────────────

void _showSafeSpendBreakdownSheet(
  BuildContext context,
  DailySafeSpendCalculation calc,
) {
  final hasSafeSpend = calc.dailySafeSpend > 0;
  final accentColor = hasSafeSpend ? DashboardTokens.bermuda : DashboardTokens.apricot;
  final formattedPayday = DateFormat('MMMM d, yyyy').format(calc.nextPayday);
  final shortPayday = DateFormat('MMM d').format(calc.nextPayday);

  ModernBottomSheet.show(
    context: context,
    title: 'Kasya Ba Today? Math Breakdown',
    subtitle: '100% deterministic calculation of your safe daily spending allowance.',
    showDragHandle: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formula Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.functions_rounded,
                    size: 16,
                    color: DashboardTokens.bermuda,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EXACT DETERMINISTIC FORMULA',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: DashboardTokens.bermuda,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DashboardTokens.ebony.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Text(
                  'Daily Safe Spend = Math.max(0, (Total Liquid Balance - Unpaid Bills Due Before Next Payday - Scheduled Goal Contributions) / Days Until Next Payday)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: DashboardTokens.periwinkleGray,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'In simple words: (Available Cash Pool) ÷ (Days Left Until Payday)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Numerator Details (Cash Pool)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: DashboardTokens.periwinkleGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NUMERATOR (SAFE CASH BUFFER)',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Your Available Cash Pool (Cash minus commitments)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeterministicRow(
                label: 'Total Liquid Balance',
                value: CurrencyFormatter.format(calc.totalLiquidBalance),
                prefix: '+',
                valueColor: DashboardTokens.bermuda,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Unpaid Bills Due (before $shortPayday)',
                sublabel:
                    '${calc.unpaidBillsCount} unpaid bill${calc.unpaidBillsCount == 1 ? '' : 's'} due on or before payday',
                value: CurrencyFormatter.format(calc.unpaidBillsDue),
                prefix: '-',
                valueColor: calc.unpaidBillsDue > 0
                    ? DashboardTokens.apricot
                    : DashboardTokens.periwinkleGraySubtitle,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Scheduled Goal Contributions',
                sublabel:
                    '${calc.activeGoalsCount} active goal${calc.activeGoalsCount == 1 ? '' : 's'} prorated to next payday',
                value: CurrencyFormatter.format(calc.scheduledGoalContributions),
                prefix: '-',
                valueColor: calc.scheduledGoalContributions > 0
                    ? DashboardTokens.poloBlue
                    : DashboardTokens.periwinkleGraySubtitle,
              ),

              if (calc.goalDetails.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashboardTokens.ebony.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DashboardTokens.poloBlue22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOAL PRORATION BREAKDOWN',
                        style: GoogleFonts.dmSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: DashboardTokens.poloBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final detail in calc.goalDetails) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.track_changes_rounded,
                              size: 14,
                              color: DashboardTokens.bermuda,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.title,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: DashboardTokens.periwinkleGray,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${CurrencyFormatter.format(detail.dailyRate)}/day × ${detail.daysCounted} days until payday',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10.5,
                                      color: DashboardTokens.periwinkleGraySubtitle,
                                      fontFeatures: CurrencyFormatter.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(detail.totalContribution)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.poloBlue,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                        if (detail != calc.goalDetails.last)
                          const Divider(
                            color: DashboardTokens.poloBlue22,
                            height: 12,
                          ),
                      ],
                    ],
                  ),
                ),
              ],

              const Divider(color: DashboardTokens.poloBlue22, height: 20),
              _buildDeterministicRow(
                label: 'Safe Available Cash',
                value: CurrencyFormatter.format(calc.numerator),
                prefix: '=',
                isTotal: true,
                valueColor: calc.numerator > 0
                    ? DashboardTokens.periwinkleGray
                    : DashboardTokens.apricot,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Denominator Details (Payday Timeline)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: DashboardTokens.poloBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DENOMINATOR (PAYDAY TIMELINE)',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: DashboardTokens.poloBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Days Until Next Payday (Cash stretch period)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeterministicRow(
                label: 'Next Configured Payday',
                sublabel: 'Schedule: ${calc.paydaySchedule}',
                value: formattedPayday,
                valueColor: DashboardTokens.periwinkleGray,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Days Until Next Payday',
                value: '÷ ${calc.daysUntilPayday} days',
                valueColor: DashboardTokens.poloBlue,
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Result Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasSafeSpend
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY SAFE SPEND ALLOWANCE',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.format(calc.dailySafeSpend),
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ day',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contextual Explanation for ₱0.00
        if (!hasSafeSpend) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: DashboardTokens.bigStone,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: DashboardTokens.apricot.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: DashboardTokens.apricot,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calc.totalLiquidBalance <= 0
                            ? 'Why is your daily safe spend ₱0.00?'
                            : 'Savings & Bills Protection Active',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.apricot,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  calc.totalLiquidBalance <= 0
                      ? 'You have ₱0.00 recorded in your balance right now, but your ${calc.activeGoalsCount > 0 ? "active goal requires ${CurrencyFormatter.format(calc.scheduledGoalContributions)}" : "upcoming bills require funding"} before your next payday ($shortPayday). Kasyaba holds your allowance at ₱0.00 so you don\'t overspend money you don\'t have yet.'
                      : 'Your upcoming bills (${CurrencyFormatter.format(calc.unpaidBillsDue)}) and goal contributions (${CurrencyFormatter.format(calc.scheduledGoalContributions)}) exceed your current cash. Kasyaba holds your daily spending at ₱0.00 to keep your essential commitments protected until payday.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: DashboardTokens.periwinkleGraySubtitle,
                    height: 1.4,
                  ),
                ),
                if (calc.totalLiquidBalance <= 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/transactions/add', extra: 'income');
                      },
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text(
                        '+ Log Starting Cash / Balance',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DashboardTokens.bermuda,
                        side: const BorderSide(color: DashboardTokens.bermuda),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardTokens.periwinkleGray,
            foregroundColor: DashboardTokens.ebony,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Close Breakdown',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

Widget _buildDeterministicRow({
  required String label,
  String? sublabel,
  required String value,
  String? prefix,
  bool isTotal = false,
  Color? valueColor,
}) {
  final effectiveColor = valueColor ?? DashboardTokens.periwinkleGray;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: isTotal ? 13 : 12,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal
                    ? DashboardTokens.periwinkleGray
                    : DashboardTokens.periwinkleGraySubtitle,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 1),
              Text(
                sublabel,
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
            ],
          ],
        ),
      ),
      if (prefix != null) ...[
        Text(
          '$prefix ',
          style: GoogleFonts.dmSans(
            fontSize: isTotal ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: effectiveColor,
          ),
        ),
      ],
      Text(
        value,
        style: GoogleFonts.dmSans(
          fontSize: isTotal ? 15 : 13,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
          color: effectiveColor,
          fontFeatures: CurrencyFormatter.tabularFigures,
        ),
      ),
    ],
  );
}
