import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/cache_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validated_input.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';

final _uuidPattern = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

void _showCreateBudgetSheet(BuildContext context) {
  showKasyabaSheet<void>(context: context, builder: (ctx) => const _CreateBudgetSheet());
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
    final isOnline = ref.watch(isOnlineProvider);

    final categories = categoriesAsync.valueOrNull ?? defaultCategoriesList;
    final categoryMap = {for (final c in categories) c.id: c.name};

    return Scaffold(
      backgroundColor: context.kColors.canvas,
      body: Container(
        decoration: BoxDecoration(
          gradient: context.kColors.backgroundGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: context.kColors.textPrimary,
                  backgroundColor: context.kColors.card,
                  onRefresh: () async => ref.invalidate(budgetStatusProvider),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, DashboardTokens.dockClearance),
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
                                  color: context.kColors.card,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: context.kColors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.chevron_left_rounded,
                                  color: context.kColors.textPrimary,
                                  size: 26,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                'Budgets',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: context.kColors.textPrimary,
                                ),
                              ),
                            ),
                            SpringTouch(
                              onTap: isOnline
                                  ? () => _showCreateBudgetSheet(context)
                                  : null,
                              child: Opacity(
                                opacity: isOnline ? 1 : 0.5,
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: context.kColors.card,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: context.kColors.cardBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: context.kColors.textPrimary,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (!isOnline) ...[
                        const OfflineStatusBadge(
                          snapshotKey: CacheService.snapshotKeyBudgets,
                        ),
                        const SizedBox(height: 10),
                        const NeedsInternetNotice(
                          message:
                              'Creating or deleting budgets needs an internet connection.',
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Monthly Budget Overview Hero Card
                      FadeSlideEntrance.staggered(
                        index: 1,
                        child: budgetAsync.when(
                          loading: () => const KasyabaLoadingSkeleton(lines: 4),
                          error: (err, _) => Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: context.kColors.card,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: context.kColors.cardBorder,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: context.kColors.danger,
                                      size: 22,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Could not load your budget',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: context.kColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  friendlyErrorMessage(err),
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color:
                                        context.kColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: SpringTouch(
                                    onTap: () =>
                                        ref.invalidate(budgetStatusProvider),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.kColors.primaryButton,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.w700,
                                          color: context.kColors.onPrimaryButton,
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
                              badgeBg = context.kColors.dangerTint;
                              badgeColor = context.kColors.danger;
                              progressColor = context.kColors.danger;
                            } else if (pct >= 80) {
                              badgeBg = context.kColors.warningTint;
                              badgeColor = context.kColors.warning;
                              progressColor = context.kColors.warning;
                            } else {
                              badgeBg = context.kColors.successTint;
                              badgeColor = context.kColors.success;
                              progressColor = context.kColors.success;
                            }

                            final remaining =
                                (status.totalBudget - status.totalSpent);

                            return Container(
                              padding: const EdgeInsets.all(19),
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
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Monthly Budget Overview',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: context.kColors.textSecondary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: badgeBg,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          pctLabel,
                                          style: GoogleFonts.dmSans(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          CurrencyFormatter.format(
                                            status.totalSpent,
                                          ),
                                          style: GoogleFonts.bricolageGrotesque(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                context.kColors.textPrimary,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        Text(
                                          ' / ${CurrencyFormatter.format(status.totalBudget)}',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: context.kColors.textSecondary,
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
                                      backgroundColor: context.kColors.icon.withValues(alpha: 0.2),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        progressColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    remaining >= 0
                                        ? '${CurrencyFormatter.format(remaining)} left to spend this month'
                                        : '${CurrencyFormatter.format(remaining.abs())} over budget this month',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: remaining >= 0
                                          ? context.kColors.textSecondary
                                          : context.kColors.danger,
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
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            'CATEGORY BUDGETS',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: context.kColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Category Budgets Content
                      FadeSlideEntrance.staggered(
                        index: 3,
                        child: budgetAsync.when(
                          loading: () => const KasyabaLoadingSkeleton(lines: 3),
                          error: (err, _) => KasyabaErrorCard(
                            message: friendlyErrorMessage(err),
                            onRetry: () => ref.invalidate(budgetStatusProvider),
                          ),
                          data: (status) {
                            if (status.budgets.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 32,
                                ),
                                decoration: BoxDecoration(
                                  color: context.kColors.card,
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: context.kColors.cardBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: context.kColors.icon.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          Icons.pie_chart_outline_rounded,
                                          color: context.kColors.textPrimary,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No Category Budgets Set',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: context.kColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Assign monthly spending limits to categories like Food, Utilities, or Shopping.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        color: context.kColors.textSecondary,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    SpringTouch(
                                      onTap: isOnline
                                          ? () => _showCreateBudgetSheet(
                                              context,
                                            )
                                          : null,
                                      child: Opacity(
                                        opacity: isOnline ? 1 : 0.5,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                context.kColors.primaryButton,
                                            borderRadius: BorderRadius.circular(
                                              26,
                                            ),
                                          ),
                                          child: Text(
                                            'Set Category Budget',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color:
                                                  context.kColors.onPrimaryButton,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 19,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.kColors.card,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: context.kColors.cardBorder,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < status.budgets.length;
                                    i++
                                  ) ...[
                                    if (i > 0)
                                      Container(
                                        height: 1,
                                        color: context.kColors.divider,
                                      ),
                                    _buildBudgetItem(
                                      context,
                                      ref,
                                      budget: status.budgets[i],
                                      categoryName:
                                          status.budgets[i].categoryId == null
                                          ? 'Overall Budget'
                                          : categoryMap[status
                                                    .budgets[i]
                                                    .categoryId] ??
                                                'Uncategorized',
                                      isOnline: isOnline,
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
                          onTap: isOnline
                              ? () => _showCreateBudgetSheet(context)
                              : null,
                          child: Opacity(
                            opacity: isOnline ? 1 : 0.5,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: context.kColors.primaryButton,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'New Budget',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: context.kColors.onPrimaryButton,
                                ),
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
    required bool isOnline,
  }) {
    final Color statusColor;
    final Color badgeBg;
    switch (budget.status) {
      case 'exceeded':
        statusColor = context.kColors.danger;
        badgeBg = context.kColors.dangerTint;
      case 'warning':
        statusColor = context.kColors.warning;
        badgeBg = context.kColors.warningTint;
      case 'on_track':
      default:
        statusColor = context.kColors.success;
        badgeBg = context.kColors.successTint;
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
                    color: context.kColors.cardBorderStrong,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    CategoryIconHelper.getIcon(categoryName),
                    color: context.kColors.textPrimary,
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
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: context.kColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${CurrencyFormatter.format(budget.spent)} / ${CurrencyFormatter.format(budget.amount)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.kColors.textSecondary,
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
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.kColors.textSecondary,
                  size: 20,
                ),
                color: context.kColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: context.kColors.cardBorder),
                ),
                onSelected: (action) async {
                  if (action == 'delete') {
                    if (!isOnline) {
                      KasyabaToast.showInfo(
                        context,
                        'Deleting budgets needs an internet connection.',
                      );
                      return;
                    }
                    final confirmed = await showKasyabaConfirmDialog(
                      context,
                      title: 'Delete $categoryName budget?',
                      message:
                          'This will remove this monthly spending limit. Your transaction history stays intact.',
                      confirmLabel: 'Delete',
                      destructive: true,
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await ref
                            .read(budgetRepositoryProvider)
                            .deleteBudget(budget.budgetId);
                      } catch (e) {
                        if (context.mounted) {
                          KasyabaToast.showError(
                            context,
                            friendlyErrorMessage(
                              e,
                              fallback:
                                  'Unable to delete this budget. Please try again.',
                            ),
                          );
                        }
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    enabled: isOnline,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          color: context.kColors.danger,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Text(
                          isOnline
                              ? 'Delete budget'
                              : 'Delete (needs internet)',
                          style: GoogleFonts.dmSans(
                            color: context.kColors.danger,
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
              backgroundColor: context.kColors.icon.withValues(alpha: 0.2),
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

  DateTime get _startsOn {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!ref.read(isOnlineProvider)) {
      KasyabaToast.showInfo(
        context,
        'Creating budgets needs an internet connection.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) return;

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(budgetRepositoryProvider)
          .createBudget(
            amount: amount,
            startsOn: _startsOn,
            categoryId: _selectedCategoryId,
          );

      if (!mounted) return;
      KasyabaToast.showSuccess(context, 'Monthly budget created!');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      KasyabaToast.showError(
        context,
        friendlyErrorMessage(
          error,
          fallback: 'Unable to create this budget. Please try again.',
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final budgetCategories = (categoriesAsync.valueOrNull ?? const <Category>[])
        .where((category) => _uuidPattern.hasMatch(category.id))
        .toList();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AppSheet(
      color: context.kColors.canvas,
      padding: EdgeInsets.fromLTRB(20, 6, 20, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              // Title & Subtitle
              Text(
                'Create budget',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.kColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Set a monthly spending limit to protect your daily safe-to-spend.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: context.kColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Monthly Limit Pill Input Card
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(
                      'Monthly Limit',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.kColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    decoration: BoxDecoration(
                      color: context.kColors.inputFill,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: context.kColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '₱ ',
                          style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: context.kColors.textPrimary,
                          ),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            autofocus: true,
                            inputFormatters: [currencyAmountInputFormatter],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.kColors.textPrimary,
                            ),
                            cursorColor: context.kColors.textPrimary,
                            decoration: InputDecoration(
                              hintText: '10000.00',
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 16,
                                color: context.kColors.icon.withValues(alpha: 0.4),
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
                              if (parsed == null ||
                                  !parsed.isFinite ||
                                  parsed <= 0) {
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
                  Padding(
                    padding: EdgeInsets.only(left: 6, bottom: 8),
                    child: Text(
                      'Category',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.kColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 21),
                    decoration: BoxDecoration(
                      color: context.kColors.inputFill,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: context.kColors.cardBorder,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCategoryId,
                        isExpanded: true,
                        dropdownColor: context.kColors.card,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.kColors.textPrimary,
                        ),
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.kColors.textPrimary,
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
                            : (value) =>
                                  setState(() => _selectedCategoryId = value),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!isOnline) ...[
                const NeedsInternetNotice(
                  message:
                      'Creating budgets needs an internet connection. Budget limits live on the server.',
                ),
                const SizedBox(height: 12),
              ],

              // Submit Button
              PillButton(
                label: 'Create Budget',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting || !isOnline ? null : _submit,
              ),
          ],
        ),
      ),
    );
  }
}
