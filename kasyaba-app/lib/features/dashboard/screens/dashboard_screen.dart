import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/api_providers.dart';
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
        'excellent'        => AppColors.emerald500,
        'good'             => AppColors.info,
        'fair'             => AppColors.warning,
        'poor'             => AppColors.expense,
        'needs attention'  => AppColors.expense,
        _                  => AppColors.emerald500,
      };

  @override
  Widget build(BuildContext context) {
    final authState        = ref.watch(authProvider);
    final dashboardAsync   = ref.watch(dashboardProvider);
    final transactionsAsync= ref.watch(transactionsProvider);
    final goalsAsync       = ref.watch(goalsProvider);
    final billsAsync       = ref.watch(billsProvider);

    final theme        = Theme.of(context);
    final isDark       = theme.brightness == Brightness.dark;
    final displayName  = authState.displayName ?? 'User';
    final firstName    = displayName.split(' ').first;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.obsidian : AppColors.lightBg,
      body: RefreshIndicator(
        color: AppColors.emerald500,
        backgroundColor:
            isDark ? AppColors.surface800 : Colors.white,
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(transactionsProvider);
          ref.invalidate(goalsProvider);
          ref.invalidate(billsProvider);
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

                  // ── Hero Balance Card ─────────────────
                  dashboardAsync.when(
                    loading: () => _BalanceCardSkeleton(isDark: isDark),
                    error: (e, _) => _ErrorCard(message: '$e', isDark: isDark),
                    data: (data) => _HeroBalanceCard(
                      data: data,
                      isVisible: _isBalanceVisible,
                      isDark: isDark,
                      onToggleVisibility: () => setState(
                          () => _isBalanceVisible = !_isBalanceVisible),
                      onExpense: () => context.go('/transactions/add'),
                      onIncome: () => context.go('/transactions/add'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Stat Grid ────────────────────────
                  dashboardAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (data) => _StatGrid(
                      data: data,
                      isDark: isDark,
                      healthColor: _healthColor(data.healthScore),
                      onSavingsTap: () => context.go('/goals'),
                      onBudgetTap:  () => context.go('/budgets'),
                      onHealthTap:  () => context.go('/alerts'),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Forecast Card ────────────────────
                  dashboardAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (data) => _ForecastCard(
                      data: data,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Spending Breakdown ───────────────
                  dashboardAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
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
                    error: (err, _) =>
                        _ErrorCard(message: '$err', isDark: isDark),
                    data: (items) => items.isEmpty
                        ? ModernCard(
                            child: EmptyStateView(
                              title: 'No Recent Activity',
                              message: 'Add expenses or income to see them here.',
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
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (goals) => goals.isEmpty
                        ? ModernCard(
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
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (bills) => bills.isEmpty
                        ? ModernCard(
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

      // ── FAB ───────────────────────────────────────────
      floatingActionButton: _LuxuryFab(
        onPressed: () => context.go('/transactions/add'),
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
      expandedHeight: 0,
      toolbarHeight: 72,
      leading: const SizedBox.shrink(),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.obsidian,
                    AppColors.obsidian.withValues(alpha: 0.0),
                  ]
                : [
                    AppColors.lightBg,
                    AppColors.lightBg.withValues(alpha: 0.0),
                  ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: fadeAnim,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _greeting(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedL,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: firstName,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLight,
                                ),
                              ),
                              const TextSpan(text: ' '),
                              const TextSpan(
                                text: '✦',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gold400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  _AppBarAction(
                    icon: Icons.notifications_outlined,
                    isDark: isDark,
                    onTap: onNotificationsTap,
                    tooltip: 'Alerts',
                  ),
                  const SizedBox(width: 10),
                  _AppBarAction(
                    icon: Icons.settings_outlined,
                    isDark: isDark,
                    onTap: onSettingsTap,
                    tooltip: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarAction({
    required this.icon,
    required this.isDark,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? AppColors.surface700.withValues(alpha: 0.7)
                  : AppColors.lightCard,
              border: Border.all(
                color: isDark
                    ? AppColors.surface600.withValues(alpha: 0.6)
                    : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Balance Card ────────────────────────────────────────

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
        gradient: const LinearGradient(
          colors: [Color(0xFF047857), Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald600.withValues(alpha: 0.45),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative orb
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    _VisibilityToggle(
                      isVisible: isVisible,
                      onToggle: onToggleVisibility,
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Balance Amount
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    isVisible
                        ? '₱${_formatAmount(data.totalBalance)}'
                        : '₱ •••••••',
                    key: ValueKey(isVisible),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -1.2,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Income / Expense pills
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _FinancePill(
                          label: 'Income',
                          amount: isVisible
                              ? '₱${_formatAmount(data.income)}'
                              : '••••',
                          icon: Icons.arrow_downward_rounded,
                          iconColor: const Color(0xFF34D399),
                          iconBg: const Color(0xFF34D399),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      Expanded(
                        child: _FinancePill(
                          label: 'Expenses',
                          amount: isVisible
                              ? '₱${_formatAmount(data.expenses)}'
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

                // Quick Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionBtn(
                        label: 'Add Expense',
                        icon: Icons.remove_rounded,
                        onTap: onExpense,
                        isOutline: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _QuickActionBtn(
                        label: 'Add Income',
                        icon: Icons.add_rounded,
                        onTap: onIncome,
                        isOutline: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  const _VisibilityToggle({required this.isVisible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isVisible ? 'Hide' : 'Show',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBg.withValues(alpha: 0.25),
            ),
            child: Icon(icon, size: 15, color: iconBg),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
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
  final bool isOutline;
  const _QuickActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isOutline,
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
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isOutline
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white,
            border: isOutline
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isOutline
                    ? Colors.white
                    : AppColors.emerald700,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isOutline ? Colors.white : AppColors.emerald700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Stat Grid ───────────────────────────────────────────────

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
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.savings_outlined,
            label: 'Savings',
            value: '₱${_fmt(data.savings)}',
            color: AppColors.info,
            onTap: onSavingsTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.donut_small_outlined,
            label: 'Budget',
            value: '0%',
            subtitle: 'On Track',
            color: AppColors.gold500,
            onTap: onBudgetTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            icon: Icons.favorite_outline_rounded,
            label: 'Health',
            value: data.healthScore,
            color: healthColor,
            onTap: onHealthTap,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Forecast Card ────────────────────────────────────────────

class _ForecastCard extends StatelessWidget {
  final dynamic data;
  final bool isDark;
  const _ForecastCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isPositive = (data.predictedMonthEnd as double) >= 0;
    final accentColor = isPositive ? AppColors.emerald500 : AppColors.expense;

    return ModernCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [AppColors.surface800, AppColors.surface700]
            : [const Color(0xFFF0F9FF), const Color(0xFFE0F7FA)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MONTH-END FORECAST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedL,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '₱${(data.predictedMonthEnd as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive
                      ? Icons.check_circle_outline_rounded
                      : Icons.warning_amber_rounded,
                  size: 16,
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
        ],
      ),
    );
  }
}

// ─── Spending Breakdown ───────────────────────────────────────

const _chartColors = [
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF06B6D4),
];

class _SpendingSection extends StatelessWidget {
  final dynamic data;
  final bool isDark;
  final ThemeData theme;
  const _SpendingSection({
    required this.data,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Spending Breakdown'),
        const SizedBox(height: 12),
        ModernCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 46,
                    sections: [
                      for (int i = 0;
                          i < data.categoryExpenses.length;
                          i++)
                        PieChartSectionData(
                          color: _chartColors[i % _chartColors.length],
                          value: data.categoryExpenses[i].total,
                          title: '',
                          radius: 44,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 10,
                children: [
                  for (int i = 0; i < data.categoryExpenses.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _chartColors[i % _chartColors.length],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          data.categoryExpenses[i].categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedL,
                          ),
                        ),
                      ],
                    ),
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

// ─── Recent Transactions ──────────────────────────────────────

class _TransactionList extends StatelessWidget {
  final List<dynamic> items;
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
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 0,
                color: isDark
                    ? AppColors.surface600.withValues(alpha: 0.4)
                    : AppColors.lightBorder.withValues(alpha: 0.6),
              ),
            _TransactionTile(item: items[i], isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final dynamic item;
  final bool isDark;
  const _TransactionTile({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isExpense = item.isExpense as bool;
    final color = isExpense ? AppColors.expense : AppColors.income;
    final sign = isExpense ? '–' : '+';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1,
              ),
            ),
            child: Icon(
              isExpense
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),

          // Title & category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.categoryName as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedL,
                  ),
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '$sign₱${(item.amount as double).toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Goals Card ──────────────────────────────────────────────

class _GoalsCard extends StatelessWidget {
  final List<dynamic> goals;
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
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          for (final goal in goals) ...[
            _GoalItem(goal: goal, isDark: isDark),
            if (goal != goals.last) const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final dynamic goal;
  final bool isDark;
  const _GoalItem({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final progress = (goal.progress as double).clamp(0.0, 1.0);
    final pct = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                goal.name as String,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
            Text(
              '$pct%',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.emerald500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₱${(goal.currentAmount as double).toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColors.textMutedL,
              ),
            ),
            Text(
              '₱${(goal.targetAmount as double).toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textMuted : AppColors.textMutedL,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            backgroundColor: AppColors.emerald500.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.emerald500,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Bills List ───────────────────────────────────────────────

class _BillsList extends StatelessWidget {
  final List<dynamic> bills;
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
      child: Column(
        children: [
          for (int i = 0; i < bills.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: isDark
                    ? AppColors.surface600.withValues(alpha: 0.4)
                    : AppColors.lightBorder.withValues(alpha: 0.6),
              ),
            _BillTile(bill: bills[i], isDark: isDark),
          ],
        ],
      ),
    );
  }
}

class _BillTile extends StatelessWidget {
  final dynamic bill;
  final bool isDark;
  const _BillTile({required this.bill, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final dueDate =
        (bill.dueDate as DateTime).toIso8601String().split('T')[0];
    final amount = (bill.amount as double).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: isDark ? 0.15 : 0.10),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: isDark ? 0.3 : 0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.warning,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.name as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? AppColors.textDark : AppColors.textLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due $dueDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedL,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₱$amount',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              letterSpacing: -0.3,
              color: AppColors.expense,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared Helpers ───────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? AppColors.textDark : AppColors.textLight,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.emerald500,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  final bool isDark;
  const _BalanceCardSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark ? AppColors.surface700 : AppColors.lightCard2,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
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
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppColors.surface700 : AppColors.lightCard2,
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final bool isDark;
  const _ErrorCard({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      padding: const EdgeInsets.all(16),
      borderColor: AppColors.expense.withValues(alpha: 0.3),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load data: $message',
              style: const TextStyle(
                color: AppColors.expense,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LuxuryFab extends StatelessWidget {
  final VoidCallback onPressed;
  const _LuxuryFab({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF059669), Color(0xFF10B981)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'Record',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        tooltip: 'Add Transaction',
      ),
    );
  }
}
