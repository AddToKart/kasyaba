import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../app/theme/app_theme.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isBalanceVisible = true;
  late final AnimationController _headerController;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerFade = CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOut,
    );
    _headerController.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Color _healthColor(String grade) => switch (grade.toLowerCase()) {
    'excellent' => AppColors.emerald500,
    'good' => AppColors.info,
    'fair' => AppColors.warning,
    'poor' => AppColors.expense,
    'needs attention' => AppColors.expense,
    _ => AppColors.emerald500,
  };

  void _showBufferHealthSheet(BuildContext context, dynamic data) {
    final runwayDays = _StatGrid._calculateRunway(
      (data.totalBalance as num).toDouble(),
      (data.expenses as num).toDouble(),
    );
    final now = DateTime.now();
    final dayOfMonth = now.day.clamp(1, 31);
    final expenses = (data.expenses as num).toDouble();
    final dailyBurn = expenses > 0 ? (expenses / dayOfMonth) : 0.0;
    final healthScore = data.healthScore as String;

    ModernBottomSheet.show(
      context: context,
      title: 'Cash Buffer & Health',
      subtitle:
          'Deterministic calculation of your liquid runway and spending capacity.',
      showDragHandle: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface700.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.subtleBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _healthColor(healthScore).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _healthColor(healthScore).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(
                    Icons.shield_outlined,
                    color: _healthColor(healthScore),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Status: $healthScore',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _healthColor(healthScore),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _buildHealthInfoRow(
            label: 'Total Liquid Balance',
            value: CurrencyFormatter.format(data.totalBalance),
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 10),
          _buildHealthInfoRow(
            label: 'Average Daily Spend',
            value: dailyBurn > 0
                ? '${CurrencyFormatter.format(dailyBurn)} / day'
                : '₱0.00 / day',
            icon: Icons.local_fire_department_outlined,
          ),
          const SizedBox(height: 10),
          _buildHealthInfoRow(
            label: 'Estimated Survival Buffer',
            value: '$runwayDays days without new income',
            icon: Icons.timer_outlined,
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface800,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.subtleBorder),
            ),
            child: const Text(
              'Your cash buffer estimates how long your current liquid accounts can cover typical daily living costs. A buffer over 30 days is healthy, while over 90 days provides strong financial resilience.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
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
              backgroundColor: AppColors.emerald500,
              foregroundColor: Colors.black,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
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

  Widget _buildHealthInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.subtleBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.emerald400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
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

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = authState.displayName ?? 'User';
    final firstName = displayName.split(' ').first;

    final safeSpendCalc = calculateDailySafeSpend(
      totalLiquidBalance:
          (dashboardAsync.valueOrNull?.totalBalance ?? 0.0).toDouble(),
      bills: billsAsync.valueOrNull ?? const [],
      goals: goalsAsync.valueOrNull ?? const [],
      profile: userProfileAsync.valueOrNull,
    );

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: RefreshIndicator(
        color: AppColors.emerald500,
        backgroundColor: AppColors.surface800,
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Sliver AppBar ────────────────────────────
            _DashboardAppBar(
              firstName: firstName,
              isDark: isDark,
              fadeAnim: _headerFade,
              onNotificationsTap: () => context.go('/alerts'),
              onSettingsTap: () => context.go('/settings'),
            ),

            // ── Body Content ─────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Offline / Pending Sync Status Banner ──
                  if ((dashboardAsync.valueOrNull?.isFromCache ?? false) ||
                      pendingSyncCount > 0)
                    _OfflineSyncBanner(
                      isFromCache:
                          dashboardAsync.valueOrNull?.isFromCache ?? false,
                      pendingCount: pendingSyncCount,
                      isDark: isDark,
                    ),

                  // ── Hero Balance Card (Ultra Metal Luxury) ──
                  dashboardAsync.when(
                    loading: () => _BalanceCardSkeleton(isDark: isDark),
                    error: (e, _) => _ErrorCard(
                      message: friendlyErrorMessage(e),
                      isDark: isDark,
                      onRetry: () => ref.invalidate(dashboardProvider),
                    ),
                    data: (data) => _HeroBalanceCard(
                      data: data,
                      safeSpendCalc: safeSpendCalc,
                      isVisible: _isBalanceVisible,
                      isDark: isDark,
                      onToggleVisibility: () => setState(
                        () => _isBalanceVisible = !_isBalanceVisible,
                      ),
                      onExpense: () =>
                          context.go('/transactions/add', extra: 'expense'),
                      onIncome: () =>
                          context.go('/transactions/add', extra: 'income'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stat Grid ────────────────────────
                  dashboardAsync.when(
                    loading: () => const _StatGridSkeleton(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (data) => _StatGrid(
                      data: data,
                      isDark: isDark,
                      activeGoalCount: goalsAsync.valueOrNull?.length ?? 0,
                      budgetCount:
                          budgetStatusAsync.valueOrNull?.budgetCount ?? 0,
                      healthColor: _healthColor(data.healthScore),
                      onSavingsTap: () => context.go('/goals'),
                      onBudgetTap: () => context.go('/budgets'),
                      onHealthTap: () => _showBufferHealthSheet(context, data),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Forecast Card ────────────────────
                  dashboardAsync.when(
                    loading: () => const _ForecastCardSkeleton(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (data) => _ForecastCard(data: data, isDark: isDark),
                  ),
                  const SizedBox(height: 14),
                  _PlanningTeaser(onTap: () => context.go('/planning')),
                  const SizedBox(height: 28),

                  // ── Spending Breakdown ───────────────
                  dashboardAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (data) {
                      if (data.categoryExpenses.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return _SpendingSection(
                        data: data,
                        isDark: isDark,
                        theme: theme,
                      );
                    },
                  ),

                  // ── Recent Activity ──────────────────
                  _SectionHeader(
                    title: 'Recent Activity',
                    actionLabel: 'View All',
                    onAction: () => context.go('/transactions'),
                  ),
                  const SizedBox(height: 12),
                  transactionsAsync.when(
                    loading: () => _ListSkeleton(isDark: isDark),
                    error: (err, _) => _ErrorCard(
                      message: friendlyErrorMessage(err),
                      isDark: isDark,
                      onRetry: () =>
                          ref.invalidate(paginatedTransactionsProvider),
                    ),
                    data: (items) => items.isEmpty
                        ? const ModernCard(
                            child: EmptyStateView(
                              title: 'No Recent Activity',
                              message:
                                  'Add expenses or income to see them here.',
                              icon: Icons.swap_horiz_outlined,
                            ),
                          )
                        : _TransactionList(
                            items: items.take(5).toList(),
                            isDark: isDark,
                            theme: theme,
                          ),
                  ),
                  const SizedBox(height: 28),

                  // ── Savings Goals ────────────────────
                  _SectionHeader(
                    title: 'Savings Goals',
                    actionLabel: 'View All',
                    onAction: () => context.go('/goals'),
                  ),
                  const SizedBox(height: 12),
                  goalsAsync.when(
                    loading: () => _ListSkeleton(isDark: isDark),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (goals) => goals.isEmpty
                        ? const ModernCard(
                            child: EmptyStateView(
                              title: 'No Active Goals',
                              message:
                                  'Set savings goals for your next big milestone.',
                              icon: Icons.savings_outlined,
                            ),
                          )
                        : _GoalsCard(
                            goals: goals.take(3).toList(),
                            isDark: isDark,
                            theme: theme,
                          ),
                  ),
                  const SizedBox(height: 28),

                  // ── Upcoming Bills ───────────────────
                  _SectionHeader(
                    title: 'Upcoming Bills',
                    actionLabel: 'View All',
                    onAction: () => context.go('/bills'),
                  ),
                  const SizedBox(height: 12),
                  billsAsync.when(
                    loading: () => _ListSkeleton(isDark: isDark),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (bills) => bills.isEmpty
                        ? const ModernCard(
                            child: EmptyStateView(
                              title: 'No Upcoming Bills',
                              message:
                                  'Track recurring bills to never miss a due date.',
                              icon: Icons.receipt_long_outlined,
                            ),
                          )
                        : _BillsList(
                            bills: bills.take(3).toList(),
                            isDark: isDark,
                            theme: theme,
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sliver AppBar ───────────────────────────────────────────

class _DashboardAppBar extends StatelessWidget {
  final String firstName;
  final bool isDark;
  final Animation<double> fadeAnim;
  final VoidCallback onNotificationsTap;
  final VoidCallback onSettingsTap;

  const _DashboardAppBar({
    required this.firstName,
    required this.isDark,
    required this.fadeAnim,
    required this.onNotificationsTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: false,
      floating: true,
      snap: true,
      backgroundColor: Colors.transparent,
      toolbarHeight: 76,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: FadeTransition(
        opacity: fadeAnim,
        child: Row(
          children: [
            // User Avatar Ring
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.gradientEmerald,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald500.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _greeting(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        FadeTransition(
          opacity: fadeAnim,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _AppBarAction(
                icon: Icons.notifications_outlined,
                onTap: onNotificationsTap,
                tooltip: 'Alerts',
              ),
              const SizedBox(width: 8),
              _AppBarAction(
                icon: Icons.settings_outlined,
                onTap: onSettingsTap,
                tooltip: 'Settings',
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 18) return 'Good afternoon,';
    return 'Good evening,';
  }
}

class _AppBarAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.surface700,
              border: Border.all(color: const Color(0x33334155), width: 1),
            ),
            child: Icon(icon, size: 20, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

// ─── Offline Sync Banner ──────────────────────────────────────────

class _OfflineSyncBanner extends StatelessWidget {
  final bool isFromCache;
  final int pendingCount;
  final bool isDark;

  const _OfflineSyncBanner({
    required this.isFromCache,
    required this.pendingCount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasPending = pendingCount > 0;
    final message = hasPending
        ? '$pendingCount transaction${pendingCount > 1 ? 's' : ''} saved offline • Will sync when connected'
        : 'Offline mode • Showing cached balances';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: hasPending
            ? AppColors.gold500.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPending
              ? AppColors.gold500.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.sync_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: hasPending ? AppColors.gold400 : AppColors.textMuted,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasPending ? AppColors.gold300 : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Balance Card (Ultra Wealth Metal Card Redesign) ────────

class _HeroBalanceCard extends StatelessWidget {
  final dynamic data;
  final DailySafeSpendCalculation? safeSpendCalc;
  final bool isVisible;
  final bool isDark;
  final VoidCallback onToggleVisibility;
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  const _HeroBalanceCard({
    required this.data,
    this.safeSpendCalc,
    required this.isVisible,
    required this.isDark,
    required this.onToggleVisibility,
    required this.onExpense,
    required this.onIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppColors.gradientHeroCard,
        border: Border.all(
          color: AppColors.gold500.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Decorative subtle metallic shine background orb
            Positioned(
              right: -40,
              top: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold500.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content Padding
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card Label & Visibility Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card_rounded,
                            size: 16,
                            color: AppColors.gold400,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'TOTAL LIQUID BALANCE',
                            style: TextStyle(
                              color: AppColors.gold400,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (data.isFromCache == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'CACHED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      _VisibilityToggle(
                        isVisible: isVisible,
                        onToggle: onToggleVisibility,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Prominent Formatted Balance
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      isVisible
                          ? CurrencyFormatter.format(data.totalBalance)
                          : '₱ •••••••',
                      key: ValueKey(isVisible),
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                        letterSpacing: -0.5,
                        height: 1.1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── "Kasya Ba Today?" Daily Safe-to-Spend Section ──
                  if (safeSpendCalc != null) ...[
                    _DailySafeSpendSection(
                      calc: safeSpendCalc!,
                      isVisible: isVisible,
                      onTapBreakdown: () => _showSafeSpendBreakdownSheet(
                        context,
                        safeSpendCalc!,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Income / Expense Capsules Row
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface800.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.subtleBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FinancePill(
                            label: 'Income',
                            amount: isVisible
                                ? CurrencyFormatter.format(data.income)
                                : '••••',
                            icon: Icons.arrow_downward_rounded,
                            iconColor: AppColors.emerald500,
                            iconBg: AppColors.emerald500,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.subtleBorder,
                        ),
                        Expanded(
                          child: _FinancePill(
                            label: 'Expenses',
                            amount: isVisible
                                ? CurrencyFormatter.format(data.expenses)
                                : '••••',
                            icon: Icons.arrow_upward_rounded,
                            iconColor: Colors.white,
                            iconBg: const Color(0xFFF87171),
                            leftPadding: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons (High contrast modern buttons)
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionBtn(
                          label: 'Add Expense',
                          icon: Icons.remove_rounded,
                          onTap: onExpense,
                          isIncome: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickActionBtn(
                          label: 'Add Income',
                          icon: Icons.add_rounded,
                          onTap: onIncome,
                          isIncome: true,
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
    );
  }
}

// ─── "Kasya Ba Today?" Daily Safe Spend Section Widget ─────────────

class _DailySafeSpendSection extends StatelessWidget {
  final DailySafeSpendCalculation calc;
  final bool isVisible;
  final VoidCallback onTapBreakdown;

  const _DailySafeSpendSection({
    required this.calc,
    required this.isVisible,
    required this.onTapBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final hasSafeSpend = calc.dailySafeSpend > 0;
    final accentColor = hasSafeSpend ? AppColors.emerald500 : AppColors.gold500;
    final formattedDate = DateFormat('MMM d').format(calc.nextPayday);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTapBreakdown,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xE6090D16),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Status Badge & Info Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.4),
                            width: 0.75,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'KASYA BA TODAY?',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'DAILY SAFE SPEND',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                  Tooltip(
                    message: 'View deterministic math breakdown',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Breakdown',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: AppColors.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Prominent Daily Safe Spend Metric
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    isVisible
                        ? CurrencyFormatter.format(calc.dailySafeSpend)
                        : '₱ ••••',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color:
                          hasSafeSpend ? AppColors.emerald400 : AppColors.gold400,
                      fontFeatures: CurrencyFormatter.tabularFigures,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/ day',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Days until payday caption
              Text(
                'for the next ${calc.daysUntilPayday} days until $formattedDate payday',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),

              // Exact formula summary snippet
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calculate_outlined,
                      size: 13,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '(${CurrencyFormatter.format(calc.numerator)} safe cash) ÷ ${calc.daysUntilPayday} days',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.textMuted,
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

// ─── Kasya Ba Today? Math Breakdown Sheet ──────────────────────────

void _showSafeSpendBreakdownSheet(
  BuildContext context,
  DailySafeSpendCalculation calc,
) {
  final hasSafeSpend = calc.dailySafeSpend > 0;
  final accentColor = hasSafeSpend ? AppColors.emerald500 : AppColors.gold500;
  final formattedPayday = DateFormat('MMMM d, yyyy').format(calc.nextPayday);
  final shortPayday = DateFormat('MMM d').format(calc.nextPayday);

  ModernBottomSheet.show(
    context: context,
    title: 'Kasya Ba Today? Math Breakdown',
    subtitle:
        '100% deterministic calculation of your safe daily spending allowance.',
    showDragHandle: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formula Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface700.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.functions_rounded,
                    size: 16,
                    color: AppColors.emerald400,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'EXACT DETERMINISTIC FORMULA',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.emerald400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: const Text(
                  'Daily Safe Spend = Math.max(0, (Total Liquid Balance - Unpaid Bills Due Before Next Payday - Scheduled Goal Contributions) / Days Until Next Payday)',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: Color(0xFFE2E8F0),
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Numerator Details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: AppColors.gold400,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'NUMERATOR (SAFE CASH BUFFER)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.gold400,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDeterministicRow(
                label: 'Total Liquid Balance',
                value: CurrencyFormatter.format(calc.totalLiquidBalance),
                prefix: '+',
                valueColor: AppColors.emerald400,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Unpaid Bills Due (before $shortPayday)',
                sublabel:
                    '${calc.unpaidBillsCount} unpaid bill${calc.unpaidBillsCount == 1 ? '' : 's'} due on or before payday',
                value: CurrencyFormatter.format(calc.unpaidBillsDue),
                prefix: '-',
                valueColor: calc.unpaidBillsDue > 0
                    ? const Color(0xFFF87171)
                    : AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Scheduled Goal Contributions',
                sublabel:
                    '${calc.activeGoalsCount} active goal${calc.activeGoalsCount == 1 ? '' : 's'} prorated to next payday',
                value: CurrencyFormatter.format(calc.scheduledGoalContributions),
                prefix: '-',
                valueColor: calc.scheduledGoalContributions > 0
                    ? AppColors.gold400
                    : AppColors.textMuted,
              ),
              const Divider(color: AppColors.subtleBorder, height: 20),
              _buildDeterministicRow(
                label: 'Safe Available Cash',
                value: CurrencyFormatter.format(calc.numerator),
                prefix: '=',
                isTotal: true,
                valueColor: calc.numerator > 0
                    ? AppColors.textDark
                    : const Color(0xFFF87171),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Denominator Details
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface800,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.subtleBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.info,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'DENOMINATOR (PAYDAY TIMELINE)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDeterministicRow(
                label: 'Next Configured Payday',
                sublabel: 'Schedule: ${calc.paydaySchedule}',
                value: formattedPayday,
                valueColor: AppColors.textDark,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Days Until Next Payday',
                value: '÷ ${calc.daysUntilPayday} days',
                valueColor: AppColors.info,
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
                    const Text(
                      'DAILY SAFE SPEND ALLOWANCE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.format(calc.dailySafeSpend),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '/ day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
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
        const SizedBox(height: 18),

        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surface700,
            foregroundColor: AppColors.textDark,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.subtleBorder),
            ),
          ),
          child: const Text(
            'Close Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold),
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
  Color valueColor = AppColors.textDark,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 13 : 12,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                color: isTotal ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 1),
              Text(
                sublabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
      if (prefix != null) ...[
        Text(
          '$prefix ',
          style: TextStyle(
            fontSize: isTotal ? 14 : 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
      Text(
        value,
        style: TextStyle(
          fontSize: isTotal ? 15 : 13,
          fontWeight: isTotal ? FontWeight.w800 : FontWeight.w700,
          color: valueColor,
          fontFeatures: CurrencyFormatter.tabularFigures,
        ),
      ),
    ],
  );
}

class _VisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  const _VisibilityToggle({required this.isVisible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final actionLabel = isVisible ? 'Hide balance' : 'Show balance';
    return Tooltip(
      message: actionLabel,
      child: Semantics(
        button: true,
        label: actionLabel,
        onTap: onToggle,
        excludeSemantics: true,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface700,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0x40334155),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isVisible ? 'Hide' : 'Show',
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FinancePill extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final bool leftPadding;

  const _FinancePill({
    required this.label,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.leftPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding ? 14 : 0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg.withValues(alpha: 0.2),
            ),
            child: Icon(icon, size: 16, color: iconBg),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isIncome;

  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isIncome ? AppColors.emerald500 : AppColors.surface700,
            border: isIncome
                ? null
                : Border.all(color: AppColors.subtleBorder, width: 1),
            boxShadow: isIncome
                ? [
                    BoxShadow(
                      color: AppColors.emerald500.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isIncome ? Colors.black : AppColors.gold400,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isIncome ? Colors.black : AppColors.textDark,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Grid (Modern Financial Intelligence Cards) ──────────

class _StatGrid extends StatelessWidget {
  final dynamic data;
  final bool isDark;
  final int activeGoalCount;
  final int budgetCount;
  final Color healthColor;
  final VoidCallback onSavingsTap;
  final VoidCallback onBudgetTap;
  final VoidCallback onHealthTap;

  const _StatGrid({
    required this.data,
    required this.isDark,
    required this.activeGoalCount,
    required this.budgetCount,
    required this.healthColor,
    required this.onSavingsTap,
    required this.onBudgetTap,
    required this.onHealthTap,
  });

  @override
  Widget build(BuildContext context) {
    final runwayDays = _calculateRunway(
      (data.totalBalance as num).toDouble(),
      (data.expenses as num).toDouble(),
    );
    final hasBudgets = budgetCount > 0;
    final budgetPercent = (data.budgetUsedPercent as num).toDouble();
    final savingsAmount = (data.savings as num).toDouble();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.savings_outlined,
              label: 'Saved (MTD)',
              value: CurrencyFormatter.formatCompact(savingsAmount),
              subtitle: activeGoalCount > 0
                  ? '$activeGoalCount Goal${activeGoalCount == 1 ? "" : "s"}'
                  : (savingsAmount > 0 ? 'Goal Funds' : 'No Goals'),
              color: AppColors.info,
              onTap: onSavingsTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              icon: Icons.donut_small_outlined,
              label: hasBudgets ? 'Budget Used' : 'Budget',
              value: hasBudgets
                  ? '${budgetPercent.toStringAsFixed(0)}%'
                  : 'Not Set',
              subtitle: hasBudgets
                  ? _budgetStatusLabel(budgetPercent)
                  : 'Tap to Set',
              color: hasBudgets
                  ? (budgetPercent >= 100
                      ? AppColors.expense
                      : (budgetPercent >= 90
                          ? AppColors.warning
                          : AppColors.gold500))
                  : AppColors.gold500,
              onTap: onBudgetTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              icon: Icons.shield_outlined,
              label: 'Cash Buffer',
              value: runwayDays >= 90 ? '90+ Days' : '$runwayDays Days',
              subtitle: data.healthScore as String,
              color: healthColor,
              onTap: onHealthTap,
            ),
          ),
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

  String _budgetStatusLabel(double percentUsed) {
    if (percentUsed >= 100) return 'Over Budget';
    if (percentUsed >= 90) return 'Near Limit';
    return 'On Track';
  }
}

// ─── Forecast Card (Month-End Cash Flow & Trend Chart) ────────

class _ForecastCard extends StatelessWidget {
  final dynamic data;
  final bool isDark;
  const _ForecastCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPositive = (data.predictedMonthEnd as num).toDouble() >= 0;
    final accentColor = isPositive ? AppColors.emerald500 : AppColors.expense;

    final double projectedInc =
        (data.projectedIncome as num? ?? 0.0).toDouble() > 0
            ? (data.projectedIncome as num).toDouble()
            : (data.income as num).toDouble();
    final double projectedExp =
        (data.projectedExpenses as num? ?? 0.0).toDouble() > 0
            ? (data.projectedExpenses as num).toDouble()
            : (data.expenses as num).toDouble();
    final double actualInc = (data.income as num).toDouble();
    final double actualExp = (data.expenses as num).toDouble();

    final double remainingInflow = (projectedInc >= actualInc)
        ? (projectedInc - actualInc)
        : 0.0;
    final double remainingOutflow = (projectedExp >= actualExp)
        ? (projectedExp - actualExp)
        : 0.0;

    final now = DateTime.now();
    final monthEndDay = DateTime(now.year, now.month + 1, 0).day;
    final outlookBadge =
        '${DateFormat('MMM').format(now).toUpperCase()} $monthEndDay OUTLOOK';

    final totalBalance = (data.totalBalance as num).toDouble();
    final predictedMonthEnd = (data.predictedMonthEnd as num).toDouble();
    final netProjectedDelta = predictedMonthEnd - totalBalance;

    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: AppColors.surfaceCard,
      borderColor: AppColors.subtleBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.emerald400,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'PROJECTED MONTH-END',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.emerald500.withValues(alpha: 0.15),
                            borderRadius:
                                BorderRadius.circular(AppTheme.tagRadius),
                            border: Border.all(
                              color: AppColors.emerald500
                                  .withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            outlookBadge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald400,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CurrencyFormatter.format(predictedMonthEnd),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textDark,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estimated cash balance on ${DateFormat('MMMM d').format(DateTime(now.year, now.month + 1, 0))}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── 3-Tile Cash Flow Bridge ───────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface800,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.subtleBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.account_tree_outlined,
                      size: 14,
                      color: AppColors.gold400,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'CASH FLOW CALCULATION',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.gold400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 3 Connected Step Cards
                Row(
                  children: [
                    // Step 1: Current Cash
                    Expanded(
                      child: _CashFlowStepTile(
                        label: 'Current Cash',
                        subtitle: 'In Wallets',
                        amount: CurrencyFormatter.format(totalBalance),
                        amountColor: AppColors.textDark,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '+',
                        style: TextStyle(
                          color: AppColors.emerald500,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Step 2: Expected Pay / Inflow
                    Expanded(
                      child: _CashFlowStepTile(
                        label: 'Expected Pay',
                        subtitle: 'Upcoming In',
                        amount: '+${CurrencyFormatter.format(remainingInflow)}',
                        amountColor: AppColors.emerald500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        '-',
                        style: TextStyle(
                          color: AppColors.expense,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Step 3: Upcoming Outflows
                    Expanded(
                      child: _CashFlowStepTile(
                        label: 'Scheduled Out',
                        subtitle: 'Bills & Spend',
                        amount: '-${CurrencyFormatter.format(remainingOutflow)}',
                        amountColor: AppColors.expense,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Result Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface700.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.subtleBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Projected Month-End Result',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            CurrencyFormatter.format(predictedMonthEnd),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isPositive
                                  ? AppColors.emerald500
                                  : AppColors.expense,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '(${netProjectedDelta >= 0 ? "+" : ""}${CurrencyFormatter.format(netProjectedDelta)})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: netProjectedDelta >= 0
                                  ? AppColors.emerald400
                                  : AppColors.expense,
                              fontFeatures: const [FontFeature.tabularFigures()],
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
          const SizedBox(height: 14),

          // Alert Reassurance Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: 18,
                  color: accentColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isPositive
                        ? 'All scheduled bills are fully covered by your projected cash buffer.'
                        : 'Warning: Upcoming bills exceed your projected cash before next payday.',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Daily Balance Trend Line Chart ─────────────
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BALANCE TREND',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                if ((data.dailyBalance as List).length < 2)
                  Container(
                    height: 110,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface800.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.subtleBorder,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.show_chart_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Insufficient data to plot trend line (requires ≥ 2 points)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 140,
                    child: Builder(
                      builder: (context) {
                        final list =
                            data.dailyBalance as List<DailyBalancePoint>;
                        final minY = _computeMinY(list);
                        final maxY = _computeMaxY(list);
                        final range = maxY - minY;
                        final interval = range > 0 ? (range / 3) : 1000.0;
                        final stepX = (list.length > 5)
                            ? (list.length / 4)
                                .clamp(1.0, 10.0)
                                .floorToDouble()
                            : 1.0;

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval:
                                  interval > 0 ? interval : 1000.0,
                              getDrawingHorizontalLine: (value) {
                                return const FlLine(
                                  color: Color(0x1F334155),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: stepX,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= list.length) {
                                      return const SizedBox.shrink();
                                    }
                                    if ((value - idx).abs() > 0.001) {
                                      return const SizedBox.shrink();
                                    }
                                    final dateStr = list[idx].date;
                                    String label = dateStr;
                                    try {
                                      final parsed = DateTime.parse(dateStr);
                                      final now = DateTime.now();
                                      if (parsed.year == now.year &&
                                          parsed.month == now.month &&
                                          parsed.day == now.day) {
                                        label = 'Today';
                                      } else {
                                        label = DateFormat('MMM d')
                                            .format(parsed);
                                      }
                                    } catch (_) {
                                      label = dateStr.split('-').last;
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _buildBalanceSpots(
                                  list,
                                  'balance',
                                ),
                                isCurved: true,
                                preventCurveOverShooting: true,
                                color: AppColors.info,
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppColors.info
                                          .withValues(alpha: 0.22),
                                      AppColors.info.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              LineChartBarData(
                                spots: _buildBalanceSpots(
                                  list,
                                  'projected',
                                ),
                                isCurved: true,
                                preventCurveOverShooting: true,
                                color: AppColors.emerald500.withValues(
                                  alpha: 0.7,
                                ),
                                barWidth: 2,
                                dashArray: [5, 5],
                                dotData: const FlDotData(show: false),
                              ),
                            ],
                            minY: minY,
                            maxY: maxY,
                          ),
                        );
                      },
                    ),
                  ),
                if ((data.dailyBalance as List).length >= 2) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const _LegendDot(
                        color: AppColors.info,
                        label: 'Actual Balance',
                      ),
                      const SizedBox(width: 16),
                      _LegendDot(
                        color: AppColors.emerald500.withValues(alpha: 0.7),
                        label: 'Projected Outlook',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashFlowStepTile extends StatelessWidget {
  final String label;
  final String subtitle;
  final String amount;
  final Color amountColor;

  const _CashFlowStepTile({
    required this.label,
    required this.subtitle,
    required this.amount,
    required this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface700.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.subtleBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: amountColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningTeaser extends StatelessWidget {
  final VoidCallback onTap;

  const _PlanningTeaser({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      gradient: const LinearGradient(
        colors: [Color(0xFF182234), Color(0xFF101722)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.gold500.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_graph_rounded,
              color: AppColors.gold400,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan before you spend',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'See your 30-day runway and test a decision in Scenario Lab.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.gold400),
        ],
      ),
    );
  }
}

// ─── Forecast Helpers ──────────────────────────────────────────

List<FlSpot> _buildBalanceSpots(List<DailyBalancePoint> list, String field) {
  return [
    for (int i = 0; i < list.length; i++)
      FlSpot(
        i.toDouble(),
        field == 'balance'
            ? list[i].balance
            : (list[i].projected ?? list[i].balance),
      ),
  ];
}

double _computeMinY(List<DailyBalancePoint> list) {
  double min = double.infinity;
  for (final item in list) {
    final b = item.balance;
    final p = item.projected ?? b;
    final m = b < p ? b : p;
    if (m < min) min = m;
  }
  return min == double.infinity ? 0 : min * 0.95;
}

double _computeMaxY(List<DailyBalancePoint> list) {
  double max = double.negativeInfinity;
  for (final item in list) {
    final b = item.balance;
    final p = item.projected ?? b;
    final m = b > p ? b : p;
    if (m > max) max = m;
  }
  return max == double.negativeInfinity ? 1 : max * 1.05;
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

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
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

// ─── Spending Breakdown ───────────────────────────────────────

const _chartColors = [
  AppColors.emerald500,
  AppColors.info,
  AppColors.gold500,
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
];

class _SpendingSection extends StatelessWidget {
  final DashboardData data;
  final bool isDark;
  final ThemeData theme;
  const _SpendingSection({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cats = data.categoryExpenses;
    final total = cats.fold<double>(0, (sum, cat) => sum + cat.total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Spending Breakdown'),
        const SizedBox(height: 12),
        ModernCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 160,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: [
                          for (int i = 0; i < cats.length; i++)
                            PieChartSectionData(
                              color: _chartColors[i % _chartColors.length],
                              value: cats[i].total,
                              title: total > 0
                                  ? '${(cats[i].total / total * 100).toStringAsFixed(0)}%'
                                  : '',
                              radius: 40,
                              titleStyle: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(total),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: [
                  for (int i = 0; i < cats.length; i++) ...[
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _chartColors[i % _chartColors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cats[i].categoryName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(cats[i].total),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    if (i < cats.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

// ─── Transaction List ──────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  final List<TransactionEntry> items;
  final bool isDark;
  final ThemeData theme;

  const _TransactionList({
    required this.items,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderColor: AppColors.subtleBorder,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _TransactionTile(item: items[i], isDark: isDark, theme: theme),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 68, color: AppColors.subtleBorder),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final TransactionEntry item;
  final bool isDark;
  final ThemeData theme;

  const _TransactionTile({
    required this.item,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isExpense = item.isExpense;
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final categoryColor = CategoryIconHelper.getColor(
      item.categoryName,
      isExpense: isExpense,
    );
    final categoryIcon = CategoryIconHelper.getIcon(item.categoryName);
    final dateStr =
        '${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}';
    final primaryTitle = item.title.isNotEmpty ? item.title : item.categoryName;
    final subtitleText = '${item.categoryName} • $dateStr';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: categoryColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(categoryIcon, color: categoryColor, size: 20),
      ),
      title: Text(
        primaryTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textDark,
        ),
      ),
      subtitle: Text(
        subtitleText,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
      trailing: Text(
        CurrencyFormatter.formatSigned(item.amount, isExpense: isExpense),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
          color: amountColor,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// ─── Goals Card ────────────────────────────────────────────────

class _GoalsCard extends StatelessWidget {
  final List<SavingsGoal> goals;
  final bool isDark;
  final ThemeData theme;

  const _GoalsCard({
    required this.goals,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.subtleBorder,
      child: Column(
        children: [
          for (int i = 0; i < goals.length; i++) ...[
            _GoalRow(goal: goals[i], isDark: isDark),
            if (i < goals.length - 1) const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;

  const _GoalRow({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final pct = (goal.progress * 100).clamp(0, 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                goal.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)} ($pct%)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald500,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: goal.progress.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: const Color(0xFF182234),
            color: AppColors.emerald500,
          ),
        ),
      ],
    );
  }
}

// ─── Bills List ────────────────────────────────────────────────

class _BillsList extends StatelessWidget {
  final List<BillItem> bills;
  final bool isDark;
  final ThemeData theme;

  const _BillsList({
    required this.bills,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderColor: AppColors.subtleBorder,
      child: Column(
        children: [
          for (int i = 0; i < bills.length; i++) ...[
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold500.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.receipt_rounded,
                  color: AppColors.gold400,
                  size: 20,
                ),
              ),
              title: Text(
                bills[i].name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              subtitle: Text(
                'Due: ${bills[i].dueDate.toIso8601String().split('T').first}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              trailing: Text(
                CurrencyFormatter.format(bills[i].amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textDark,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (i < bills.length - 1)
              const Divider(height: 1, indent: 68, color: AppColors.subtleBorder),
          ],
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: AppColors.textDark,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold400,
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.gold400,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Skeletons & Errors ───────────────────────────────────────

class _SkeletonBone extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const _SkeletonBone({
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<_SkeletonBone> createState() => _SkeletonBoneState();
}

class _SkeletonBoneState extends State<_SkeletonBone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.surface700.withValues(alpha: _animation.value),
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  final bool isDark;
  const _BalanceCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x33334155),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SkeletonBone(width: 140, height: 14, borderRadius: 6),
              _SkeletonBone(width: 50, height: 24, borderRadius: 12),
            ],
          ),
          SizedBox(height: 16),
          _SkeletonBone(width: 190, height: 36, borderRadius: 8),
          SizedBox(height: 20),
          _BalanceCapsuleSkeleton(),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _SkeletonBone(height: 44, borderRadius: 14)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonBone(height: 44, borderRadius: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceCapsuleSkeleton extends StatelessWidget {
  const _BalanceCapsuleSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0x22334155),
          width: 1,
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Row(
              children: [
                _SkeletonBone(width: 32, height: 32, borderRadius: 16),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBone(width: 45, height: 10, borderRadius: 4),
                    SizedBox(height: 6),
                    _SkeletonBone(width: 70, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _SkeletonBone(width: 32, height: 32, borderRadius: 16),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBone(width: 55, height: 10, borderRadius: 4),
                    SizedBox(height: 6),
                    _SkeletonBone(width: 70, height: 14, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatGridSkeleton extends StatelessWidget {
  const _StatGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatCardSkeleton()),
        SizedBox(width: 10),
        Expanded(child: _StatCardSkeleton()),
        SizedBox(width: 10),
        Expanded(child: _StatCardSkeleton()),
      ],
    );
  }
}

class _StatCardSkeleton extends StatelessWidget {
  const _StatCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0x33334155),
          width: 1,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBone(width: 28, height: 28, borderRadius: 14),
          SizedBox(height: 12),
          _SkeletonBone(width: 44, height: 11, borderRadius: 4),
          SizedBox(height: 6),
          _SkeletonBone(width: 60, height: 18, borderRadius: 6),
        ],
      ),
    );
  }
}

class _ForecastCardSkeleton extends StatelessWidget {
  const _ForecastCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      backgroundColor: AppColors.surfaceCard,
      borderColor: const Color(0x33334155),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBone(width: 42, height: 42, borderRadius: 12),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBone(width: 120, height: 14, borderRadius: 4),
                    SizedBox(height: 6),
                    _SkeletonBone(width: 160, height: 11, borderRadius: 4),
                  ],
                ),
              ),
              _SkeletonBone(width: 75, height: 24, borderRadius: 12),
            ],
          ),
          SizedBox(height: 20),
          _SkeletonBone(height: 90, borderRadius: 12),
        ],
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  final bool isDark;
  const _ListSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x33334155),
          width: 1,
        ),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              _SkeletonBone(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBone(width: 100, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    _SkeletonBone(width: 60, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              _SkeletonBone(width: 65, height: 16, borderRadius: 4),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              _SkeletonBone(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SkeletonBone(width: 110, height: 13, borderRadius: 4),
                    SizedBox(height: 6),
                    _SkeletonBone(width: 70, height: 10, borderRadius: 4),
                  ],
                ),
              ),
              _SkeletonBone(width: 55, height: 16, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;
  const _ErrorCard({
    required this.message,
    required this.isDark,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.expense.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppColors.expense,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: TextButton.styleFrom(foregroundColor: AppColors.expense),
            ),
          ),
        ],
      ),
    );
  }
}
