import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final transactionsAsync = ref.watch(transactionsProvider);
    final goalsAsync = ref.watch(goalsProvider);
    final billsAsync = ref.watch(billsProvider);
    final pendingSyncCount = ref.watch(pendingSyncCountProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final displayName = authState.displayName ?? 'User';
    final firstName = displayName.split(' ').first;

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
                      healthColor: _healthColor(data.healthScore),
                      onSavingsTap: () => context.go('/goals'),
                      onBudgetTap: () => context.go('/budgets'),
                      onHealthTap: () => context.go('/alerts'),
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
  final bool isVisible;
  final bool isDark;
  final VoidCallback onToggleVisibility;
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  const _HeroBalanceCard({
    required this.data,
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
                  const SizedBox(height: 20),

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
  final Color healthColor;
  final VoidCallback onSavingsTap;
  final VoidCallback onBudgetTap;
  final VoidCallback onHealthTap;

  const _StatGrid({
    required this.data,
    required this.isDark,
    required this.healthColor,
    required this.onSavingsTap,
    required this.onBudgetTap,
    required this.onHealthTap,
  });

  @override
  Widget build(BuildContext context) {
    final runwayDays = _calculateRunway(data.totalBalance, data.expenses);
    final runwayText = '${runwayDays}d runway';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: StatCard(
              icon: Icons.savings_outlined,
              label: 'Savings',
              value: CurrencyFormatter.formatCompact(data.savings),
              subtitle: 'Secured',
              color: AppColors.info,
              onTap: onSavingsTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              icon: Icons.donut_small_outlined,
              label: 'Budget',
              value: '${data.budgetUsedPercent.toStringAsFixed(0)}%',
              subtitle: _budgetStatusLabel(data.budgetUsedPercent),
              color: AppColors.gold500,
              onTap: onBudgetTap,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatCard(
              icon: Icons.shield_outlined,
              label: 'Health',
              value: data.healthScore,
              subtitle: runwayText,
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
    final isPositive = (data.predictedMonthEnd as double) >= 0;
    final accentColor = isPositive ? AppColors.emerald500 : AppColors.expense;
    final String confidence = (data.confidence as String?) ?? 'medium';
    final confidenceColor = switch (confidence.toLowerCase()) {
      'high' => AppColors.emerald500,
      'low' => AppColors.warning,
      _ => AppColors.info,
    };
    final confidenceLabel = '${confidence.toUpperCase()} CONFIDENCE';

    final double projectedInc = (data.projectedIncome as double? ?? 0.0) > 0
        ? (data.projectedIncome as double)
        : (data.income as double);
    final double projectedExp = (data.projectedExpenses as double? ?? 0.0) > 0
        ? (data.projectedExpenses as double)
        : (data.expenses as double);
    final double remainingInflow = (projectedInc >= (data.income as double))
        ? (projectedInc - (data.income as double))
        : 0.0;
    final double remainingOutflow = (projectedExp >= (data.expenses as double))
        ? (projectedExp - (data.expenses as double))
        : 0.0;
    final bool hasExplicitProjection =
        (data.projectedIncome as double? ?? 0.0) > 0 ||
        (data.projectedExpenses as double? ?? 0.0) > 0;

    final String breakdownFormula = hasExplicitProjection
        ? '${CurrencyFormatter.format(data.totalBalance)} (Liquid) + ${CurrencyFormatter.format(remainingInflow)} (Pending Inflow) - ${CurrencyFormatter.format(remainingOutflow)} (Pending Outflow) = ${CurrencyFormatter.format(data.predictedMonthEnd)} (Forecast)'
        : () {
            final delta = (data.predictedMonthEnd as double) -
                (data.totalBalance as double);
            final sign = delta >= 0 ? '+' : '-';
            return '${CurrencyFormatter.format(data.totalBalance)} (Liquid) $sign ${CurrencyFormatter.format(delta.abs())} (Projected Delta) = ${CurrencyFormatter.format(data.predictedMonthEnd)} (Forecast)';
          }();

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
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: AppColors.info,
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
                          'MONTH-END FORECAST',
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
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: confidenceColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: confidenceColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            confidenceLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: confidenceColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CurrencyFormatter.format(data.predictedMonthEnd),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.textDark,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Cash flow projection based on trends and scheduled activity',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini Math Breakdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface800,
              borderRadius: BorderRadius.circular(12),
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
                      Icons.calculate_outlined,
                      size: 14,
                      color: AppColors.gold400,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'MONTH-END CASH FLOW BREAKDOWN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.gold400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  breakdownFormula,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                    fontFeatures: [FontFeature.tabularFigures()],
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Alert Warning Capsule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        ? 'Estimated balance at month-end looks healthy.'
                        : 'Warning: May not cover upcoming bills before next salary.',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
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
                if (data.dailyBalance.length < 2)
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
                        Text(
                          'Insufficient data to plot trend line (requires ≥ 2 points)',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
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
                        final minY = _computeMinY(data.dailyBalance);
                        final maxY = _computeMaxY(data.dailyBalance);
                        final range = maxY - minY;
                        final interval = range > 0 ? (range / 3) : 1000.0;

                        return LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: interval > 0
                                  ? interval
                                  : 1000.0,
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
                                  reservedSize: 18,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    final list = data.dailyBalance;
                                    if (idx < 0 || idx >= list.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        list[idx].date.split('-').last,
                                        style: const TextStyle(
                                          fontSize: 9,
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
                                  data.dailyBalance,
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
                                      AppColors.info.withValues(alpha: 0.22),
                                      AppColors.info.withValues(alpha: 0.0),
                                    ],
                                  ),
                                ),
                              ),
                              LineChartBarData(
                                spots: _buildBalanceSpots(
                                  data.dailyBalance,
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
                if (data.dailyBalance.length >= 2) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const _LegendDot(color: AppColors.info, label: 'Actual'),
                      const SizedBox(width: 16),
                      _LegendDot(
                        color: AppColors.emerald500.withValues(alpha: 0.7),
                        label: 'Projected',
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
