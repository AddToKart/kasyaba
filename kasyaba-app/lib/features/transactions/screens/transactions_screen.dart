import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../app/theme/app_theme.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.obsidian : AppColors.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _TransactionsSliverAppBar(
            isDark: isDark,
            onRefresh: () => ref.invalidate(transactionsProvider),
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.emerald500,
          backgroundColor:
              isDark ? AppColors.surface800 : Colors.white,
          onRefresh: () async => ref.invalidate(transactionsProvider),
          child: transactionsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.emerald500),
            ),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.expense, size: 32),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load transactions',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
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
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ModernCard(
                      child: EmptyStateView(
                        title: 'No Transactions Yet',
                        message:
                            'Your income and expenses will appear here.',
                        icon: Icons.swap_horiz_outlined,
                        actionLabel: 'Add Transaction',
                        onAction: () =>
                            context.go('/transactions/add'),
                      ),
                    ),
                  ],
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isExpense = item.isExpense as bool;
                  final color =
                      isExpense ? AppColors.expense : AppColors.income;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ModernCard(
                      onTap: () {},
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: color.withValues(
                                    alpha: isDark ? 0.15 : 0.10),
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: color.withValues(
                                      alpha: isDark ? 0.30 : 0.20),
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

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title as String,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? AppColors.textDark
                                          : AppColors.textLight,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isExpense ? '–' : '+'}₱${(item.amount as double).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: -0.3,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: Container(
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
          onPressed: () => context.go('/transactions/add'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'New',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          tooltip: 'Add Transaction',
        ),
      ),
    );
  }
}

class _TransactionsSliverAppBar extends StatelessWidget {
  final bool isDark;
  final VoidCallback onRefresh;
  const _TransactionsSliverAppBar({
    required this.isDark,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor:
          isDark ? AppColors.obsidian : AppColors.lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Text(
        'Transactions',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: -0.5,
          color: isDark ? Colors.white : AppColors.textLight,
        ),
      ),
      titleSpacing: 20,
      actions: [
        _AppBarIconBtn(
          icon: Icons.refresh_rounded,
          isDark: isDark,
          onTap: onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final String tooltip;
  const _AppBarIconBtn({
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
            width: 40,
            height: 40,
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
              size: 18,
              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            ),
          ),
        ),
      ),
    );
  }
}
