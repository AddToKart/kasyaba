import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/empty_state_view.dart';

class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final budgetAsync = ref.watch(budgetStatusProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categories = categoriesAsync.valueOrNull ?? defaultCategoriesList;
    final categoryMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
        title: Text(
          'Budgets',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Budget',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Budget creation coming soon')),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(budgetStatusProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Overall Monthly Budget Hero Card
            budgetAsync.when(
              loading: () => _BudgetHeroSkeleton(isDark: isDark),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading budget: $err'),
              ),
              data: (status) {
                final pct = status.overallPercent.clamp(0.0, 100.0);
                final pctLabel = '${pct.toStringAsFixed(0)}% Used';
                final Color progressColor;
                if (pct >= 100) {
                  progressColor = const Color(0xFFEF4444);
                } else if (pct >= 80) {
                  progressColor = const Color(0xFFF59E0B);
                } else {
                  progressColor = const Color(0xFFF59E0B);
                }

                return ModernCard(
                  padding: const EdgeInsets.all(20),
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                        : const [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monthly Budget Overview',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFFB45309),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              pctLabel,
                              style: const TextStyle(
                                color: Color(0xFFD97706),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₱${status.totalSpent.toStringAsFixed(2)} / ₱${status.totalBudget.toStringAsFixed(2)}',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: const Color(0xFFFDE68A),
                          valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            Text(
              'Category Budgets',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            budgetAsync.when(
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (status) {
                if (status.budgets.isEmpty) {
                  return ModernCard(
                    padding: EdgeInsets.zero,
                    child: EmptyStateView(
                      title: 'No Category Budgets Set',
                      message: 'Assign monthly spending limits to categories like Food, Utilities, or Shopping.',
                      icon: Icons.pie_chart_outline,
                      actionLabel: 'Set Category Budget',
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Budget creation coming soon')),
                        );
                      },
                    ),
                  );
                }

                return ModernCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < status.budgets.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        _BudgetTile(
                          budget: status.budgets[i],
                          categoryName: categoryMap[status.budgets[i].categoryId] ?? 'Uncategorized',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget creation coming soon')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }
}

class _BudgetHeroSkeleton extends StatelessWidget {
  final bool isDark;
  const _BudgetHeroSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? AppColors.surface700 : AppColors.lightCard2,
      ),
      child: Center(
        child: CircularProgressIndicator(color: AppColors.emerald500),
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  final BudgetItemStatus budget;
  final String categoryName;
  final bool isDark;

  const _BudgetTile({
    required this.budget,
    required this.categoryName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color statusColor;
    switch (budget.status) {
      case 'exceeded':
        statusColor = const Color(0xFFEF4444);
      case 'warning':
        statusColor = const Color(0xFFF59E0B);
      case 'on_track':
      default:
        statusColor = const Color(0xFF10B981);
    }

    final progress = (budget.percentUsed / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₱${budget.spent.toStringAsFixed(2)} / ₱${budget.amount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${budget.percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: statusColor.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}
