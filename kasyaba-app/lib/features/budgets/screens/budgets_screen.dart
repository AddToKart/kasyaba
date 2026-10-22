import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router/app_shell.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_text_field.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

void _showCreateBudgetSheet(BuildContext context) {
  ModernBottomSheet.show(
    context: context,
    title: 'Create Monthly Budget',
    subtitle:
        'Set a spending limit for this month. Keep the category as overall to track every expense.',
    child: const _CreateBudgetSheet(),
  );
}

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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Budget',
            onPressed: () => _showCreateBudgetSheet(context),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Color(0xFFEF4444),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Could not load your budget',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      friendlyErrorMessage(err),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedL,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => ref.invalidate(budgetStatusProvider),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
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
                  progressColor = AppColors.emerald500;
                }

                return ModernCard(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: isDark ? AppColors.surface800 : AppColors.lightCardSurface,
                  borderColor: AppColors.subtleBorderAdaptive(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Monthly Budget Overview',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: progressColor.withValues(alpha: 0.35),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              pctLabel,
                              style: TextStyle(
                                color: progressColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${CurrencyFormatter.format(status.totalSpent)} / ${CurrencyFormatter.format(status.totalBudget)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                color: isDark ? AppColors.textDark : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: (pct / 100).clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: isDark
                              ? AppColors.surface700
                              : AppColors.lightInputFill,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
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
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
                      message:
                          'Assign monthly spending limits to categories like Food, Utilities, or Shopping.',
                      icon: Icons.pie_chart_outline,
                      actionLabel: 'Set Category Budget',
                      onAction: () => _showCreateBudgetSheet(context),
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
                          categoryName: status.budgets[i].categoryId == null
                              ? 'Overall Budget'
                              : categoryMap[status.budgets[i].categoryId] ??
                                    'Uncategorized',
                          isDark: isDark,
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingDockFabLocation(
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom,
        gap: 20.0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBudgetSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('New Budget'),
      ),
    );
  }
}

// ─── Create Budget Sheet ──────────────────────────────────────

class _CreateBudgetSheet extends ConsumerStatefulWidget {
  const _CreateBudgetSheet();

  @override
  ConsumerState<_CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<_CreateBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  bool _isSubmitting = false;
  String? _selectedCategoryId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _startsOn {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-01';
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      final data = <String, dynamic>{
        'amount': amount.toStringAsFixed(2),
        'startsOn': _startsOn,
        'period': 'monthly',
        'isActive': true,
      };
      final categoryId = _selectedCategoryId;
      if (categoryId != null) data['categoryId'] = categoryId;

      await ref.read(dioProvider).post('/budgets', data: data);
      ref.invalidate(budgetStatusProvider);
      ref.invalidate(dashboardProvider);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Monthly budget created!'),
          backgroundColor: AppColors.emerald500,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'Unable to create this budget. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final budgetCategories = (categoriesAsync.valueOrNull ?? const <Category>[])
        .where((category) => _uuidPattern.hasMatch(category.id))
        .toList();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ModernTextField(
            controller: _amountController,
            label: 'Monthly Limit (₱)',
            hint: '10000.00',
            prefixIcon: Icons.account_balance_wallet_outlined,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter a budget amount';
              if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(value)) {
                return 'Use up to 2 decimal places';
              }
              final parsed = double.tryParse(value);
              if (parsed == null || !parsed.isFinite || parsed <= 0) {
                return 'Enter an amount greater than zero';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          const Text(
            'Category',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            initialValue: _selectedCategoryId,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.category_outlined,
                color: AppColors.emerald500,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surface700
                  : AppColors.lightInputFill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Overall budget (all categories)'),
              ),
              ...budgetCategories.map(
                (category) => DropdownMenuItem<String?>(
                  value: category.id,
                  child: Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
            onChanged: _isSubmitting
                ? null
                : (value) => setState(() => _selectedCategoryId = value),
          ),
          const SizedBox(height: 8),
          Text(
            categoriesAsync.isLoading
                ? 'Loading your categories…'
                : budgetCategories.isEmpty
                ? 'No categories available yet — this budget will cover all expenses.'
                : 'Overall budgets cover every expense this month.',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _isSubmitting ? null : _submit,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check, size: 20),
            label: Text(
              _isSubmitting ? 'Creating...' : 'Create Budget',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald500,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
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
        color: isDark ? AppColors.surface700 : AppColors.lightInputFill,
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
                        color: isDark
                            ? AppColors.textDark
                            : AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} / ${CurrencyFormatter.format(budget.amount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedL,
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
