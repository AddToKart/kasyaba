import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_client.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/motion_components.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

void _showCreateBudgetSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CreateBudgetSheet(),
  );
}

/// ─────────────────────────────────────────────────────────────
///  Luxury Design-System Aligned Budgets Screen
/// ─────────────────────────────────────────────────────────────
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetStatusProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final categories = categoriesAsync.valueOrNull ?? defaultCategoriesList;
    final categoryMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: DashboardTokens.periwinkleGray,
                  backgroundColor: DashboardTokens.bigStone,
                  onRefresh: () async => ref.invalidate(budgetStatusProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
                      // Header Row: 50x50 Squircle Back Button + Title + 50x50 Squircle Add
                      FadeSlideEntrance.staggered(
                        index: 0,
                        child: Row(
                          children: [
                            SpringTouch(
                              onTap: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/dashboard');
                                }
                              },
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: DashboardTokens.bigStone,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: DashboardTokens.poloBlue22,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.chevron_left_rounded,
                                  color: DashboardTokens.periwinkleGray,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Budgets',
                                style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.periwinkleGray,
                                ),
                              ),
                            ),
                            SpringTouch(
                              onTap: () => _showCreateBudgetSheet(context),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: DashboardTokens.bigStone,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: DashboardTokens.poloBlue22,
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_rounded,
                                  color: DashboardTokens.periwinkleGray,
                                  size: 26,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Monthly Budget Overview Hero Card
                      FadeSlideEntrance.staggered(
                        index: 1,
                        child: budgetAsync.when(
                          loading: () => Container(
                            height: 160,
                            decoration: BoxDecoration(
                              color: DashboardTokens.cello60,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: DashboardTokens.poloBlue30),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation(DashboardTokens.periwinkleGray),
                              ),
                            ),
                          ),
                          error: (err, _) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: DashboardTokens.bigStone,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: DashboardTokens.poloBlue22),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: DashboardTokens.apricot,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Could not load your budget',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  friendlyErrorMessage(err),
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SpringTouch(
                                    onTap: () => ref.invalidate(budgetStatusProvider),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: DashboardTokens.periwinkleGray,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Text(
                                        'Retry',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.ebony,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          data: (status) {
                            final pct = status.overallPercent.clamp(0.0, 100.0);
                            final pctLabel = '${pct.toStringAsFixed(0)}% Used';
                            final Color badgeBg;
                            final Color badgeColor;
                            final Color progressColor;

                            if (pct >= 100) {
                              badgeBg = DashboardTokens.apricot15;
                              badgeColor = DashboardTokens.apricot;
                              progressColor = DashboardTokens.apricot;
                            } else if (pct >= 80) {
                              badgeBg = const Color(0x26F5B942);
                              badgeColor = DashboardTokens.casablanca;
                              progressColor = DashboardTokens.casablanca;
                            } else {
                              badgeBg = DashboardTokens.bermuda15;
                              badgeColor = DashboardTokens.bermuda;
                              progressColor = DashboardTokens.bermuda;
                            }

                            final remaining = (status.totalBudget - status.totalSpent);

                            return Container(
                              padding: const EdgeInsets.all(19),
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
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Monthly Budget Overview',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          pctLabel,
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: badgeColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(status.totalSpent),
                                          style: const TextStyle(
                                            fontFamily: 'Bricolage Grotesque',
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.periwinkleGray,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          ' / ${CurrencyFormatter.format(status.totalBudget)}',
                                          style: const TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: DashboardTokens.periwinkleGraySubtitle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  // Luxury progress track
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: (pct / 100).clamp(0.0, 1.0),
                                      minHeight: 8,
                                      backgroundColor: DashboardTokens.poloBlue20,
                                      valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    remaining >= 0
                                        ? '${CurrencyFormatter.format(remaining)} left to spend this month'
                                        : '${CurrencyFormatter.format(remaining.abs())} over budget this month',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: remaining >= 0
                                          ? DashboardTokens.periwinkleGraySubtitle
                                          : DashboardTokens.apricot,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section Header: CATEGORY BUDGETS
                      FadeSlideEntrance.staggered(
                        index: 2,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: Text(
                            'CATEGORY BUDGETS',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category Budgets Content
                      FadeSlideEntrance.staggered(
                        index: 3,
                        child: budgetAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                          data: (status) {
                            if (status.budgets.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                                decoration: BoxDecoration(
                                  color: DashboardTokens.bigStone,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: DashboardTokens.poloBlue22,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: const BoxDecoration(
                                        color: DashboardTokens.poloBlue20,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.pie_chart_outline_rounded,
                                          color: DashboardTokens.periwinkleGray,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Category Budgets Set',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Bricolage Grotesque',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Assign monthly spending limits to categories like Food, Utilities, or Shopping.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SpringTouch(
                                      onTap: () => _showCreateBudgetSheet(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: DashboardTokens.periwinkleGray,
                                          borderRadius: BorderRadius.circular(26),
                                        ),
                                        child: const Text(
                                          'Set Category Budget',
                                          style: TextStyle(
                                            fontFamily: 'DM Sans',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: DashboardTokens.ebony,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
                              decoration: BoxDecoration(
                                color: DashboardTokens.bigStone,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: DashboardTokens.poloBlue22,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < status.budgets.length; i++) ...[
                                    if (i > 0)
                                      Container(
                                        height: 1,
                                        color: DashboardTokens.poloBlue16,
                                      ),
                                    _buildBudgetItem(
                                      context,
                                      ref,
                                      budget: status.budgets[i],
                                      categoryName: status.budgets[i].categoryId == null
                                          ? 'Overall Budget'
                                          : categoryMap[status.budgets[i].categoryId] ?? 'Uncategorized',
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Add Budget CTA Button at Bottom
                      FadeSlideEntrance.staggered(
                        index: 4,
                        child: SpringTouch(
                          onTap: () => _showCreateBudgetSheet(context),
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: DashboardTokens.periwinkleGray,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'New Budget',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetItem(
    BuildContext context,
    WidgetRef ref, {
    required BudgetItemStatus budget,
    required String categoryName,
  }) {
    final Color statusColor;
    final Color badgeBg;
    switch (budget.status) {
      case 'exceeded':
        statusColor = DashboardTokens.apricot;
        badgeBg = DashboardTokens.apricot15;
      case 'warning':
        statusColor = DashboardTokens.casablanca;
        badgeBg = const Color(0x26F5B942);
      case 'on_track':
      default:
        statusColor = DashboardTokens.bermuda;
        badgeBg = DashboardTokens.bermuda15;
    }

    final progress = (budget.percentUsed / 100).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: DashboardTokens.poloBlue30,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    CategoryIconHelper.getIcon(categoryName),
                    color: DashboardTokens.periwinkleGray,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} / ${CurrencyFormatter.format(budget.amount)}',
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${budget.percentUsed.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: DashboardTokens.periwinkleGraySubtitle,
                  size: 20,
                ),
                color: DashboardTokens.bigStone,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: DashboardTokens.poloBlue22),
                ),
                onSelected: (action) async {
                  if (action == 'delete') {
                    final confirmed = await showModalBottomSheet<bool>(
                      context: context,
                      useRootNavigator: true,
                      backgroundColor: Colors.transparent,
                      builder: (sheetCtx) => Container(
                        decoration: BoxDecoration(
                          color: DashboardTokens.ebony,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                          border: Border.all(color: DashboardTokens.poloBlue22),
                        ),
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 38,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: DashboardTokens.poloBlue30,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Delete $categoryName budget?',
                              style: const TextStyle(
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'This will remove this monthly spending limit.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                color: DashboardTokens.periwinkleGraySubtitle,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: SpringTouch(
                                    onTap: () => Navigator.pop(sheetCtx, false),
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(26),
                                        border: Border.all(color: DashboardTokens.kashmirBlue),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.periwinkleGray,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SpringTouch(
                                    onTap: () => Navigator.pop(sheetCtx, true),
                                    child: Container(
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: DashboardTokens.apricot,
                                        borderRadius: BorderRadius.circular(26),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.ebony,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref.read(dioProvider).delete('/budgets/${budget.budgetId}');
                        ref.invalidate(budgetStatusProvider);
                        ref.invalidate(dashboardProvider);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to delete budget: $e')),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: DashboardTokens.apricot, size: 18),
                        SizedBox(width: 10),
                        Text(
                          'Delete budget',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: DashboardTokens.apricot,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: DashboardTokens.poloBlue16,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Create Budget Sheet (Matching Luxury Dark Design System)
// ─────────────────────────────────────────────────────────────

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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: DashboardTokens.ebony,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: DashboardTokens.poloBlue22,
          width: 1,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DashboardTokens.poloBlue30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title & Subtitle
              const Text(
                'Create budget',
                style: TextStyle(
                  fontFamily: 'Bricolage Grotesque',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: DashboardTokens.periwinkleGray,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Set a monthly spending limit to protect your daily safe-to-spend.',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 14,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 20),

              // Monthly Limit Pill Input Card
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(
                      'Monthly Limit',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ),
                  Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    decoration: BoxDecoration(
                      color: DashboardTokens.bigStone,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: DashboardTokens.poloBlue22,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '₱ ',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: DashboardTokens.periwinkleGray,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            autofocus: true,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                            cursorColor: DashboardTokens.periwinkleGray,
                            decoration: const InputDecoration(
                              hintText: '10000.00',
                              hintStyle: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 16,
                                color: DashboardTokens.poloBlue40,
                              ),
                              filled: false,
                              fillColor: Colors.transparent,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return 'Enter a budget amount';
                              final parsed = double.tryParse(value);
                              if (parsed == null || !parsed.isFinite || parsed <= 0) {
                                return 'Enter an amount greater than zero';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category Selection Pill Card
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(
                      'Category',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ),
                  Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    decoration: BoxDecoration(
                      color: DashboardTokens.bigStone,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: DashboardTokens.poloBlue22,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        dropdownColor: DashboardTokens.bigStone,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: DashboardTokens.periwinkleGray,
                        ),
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: DashboardTokens.periwinkleGray,
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Submit Button
              SpringTouch(
                onTap: _isSubmitting ? null : _submit,
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: DashboardTokens.periwinkleGray,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(DashboardTokens.ebony),
                          ),
                        )
                      : const Text(
                          'Create Budget',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DashboardTokens.ebony,
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
