import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_background.dart';
import '../../../shared/widgets/kasyaba_card.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../widgets/goal_deposit_sheet.dart';

/// ─────────────────────────────────────────────────────────────
///  Goal Detail Screen (Figma Node 42:6692 — "tap a goal")
/// ─────────────────────────────────────────────────────────────
class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;
  final SavingsGoal? initialGoal;

  const GoalDetailScreen({super.key, required this.goalId, this.initialGoal});

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  bool _isDeleting = false;

  SavingsGoal? _findGoal(List<SavingsGoal> goals) {
    for (final goal in goals) {
      if (goal.id == widget.goalId) return goal;
    }
    return null;
  }

  Future<void> _handleDelete(SavingsGoal goal) async {
    final confirmed = await showKasyabaConfirmDialog(
      context,
      title: 'Delete ${goal.name}?',
      message:
          'This will delete the goal and its deposit tracking history. Your wallet balances remain untouched.',
      confirmLabel: 'Delete',
      destructive: true,
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      AppHaptics.mediumImpact();
      await ref.read(budgetRepositoryProvider).deleteGoal(widget.goalId);
      if (mounted) {
        KasyabaToast.showSuccess(
          context,
          'Goal deleted',
          subtitle: '${goal.name} was removed.',
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/goals');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            e,
            fallback: 'Could not delete goal. Please try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final goalsAsync = ref.watch(goalsProvider);
    final detailAsync = ref.watch(goalDetailProvider(widget.goalId));

    final goalsValue = goalsAsync.valueOrNull;
    final SavingsGoal? goal = goalsValue != null
        ? _findGoal(goalsValue)
        : widget.initialGoal;

    final Widget content;
    if (goal == null) {
      if (goalsAsync.hasError) {
        content = KasyabaErrorCard(
          message: friendlyErrorMessage(
            goalsAsync.error,
            fallback: 'Could not load this goal.',
          ),
          onRetry: () => ref.invalidate(goalsProvider),
        );
      } else if (goalsValue != null) {
        content = const KasyabaErrorCard(message: 'Goal not found');
      } else {
        content = const KasyabaLoadingSkeleton(lines: 4);
      }
    } else {
      content = _buildGoalContent(goal, detailAsync);
    }

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: KasyabaBackground(
        child: SizedBox.expand(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, DashboardTokens.dockClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(goal?.name ?? 'Goal'),
                const SizedBox(height: 20),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            AppHaptics.selectionClick();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/goals');
            }
          },
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: DashboardTokens.bigStone,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: DashboardTokens.poloBlue22),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: DashboardTokens.periwinkleGray,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.bricolageGrotesque(
              color: DashboardTokens.periwinkleGray,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoalContent(
    SavingsGoal goal,
    AsyncValue<Map<String, dynamic>> detailAsync,
  ) {
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    final percent = goal.targetAmount > 0
        ? ((goal.currentAmount / goal.targetAmount) * 100).clamp(0, 100).toInt()
        : 0;

    DateTime? targetDateTime;
    if (goal.targetDate != null) {
      targetDateTime = DateTime.tryParse(goal.targetDate!);
    }
    final targetDateStr = targetDateTime != null
        ? DateFormat('MMM d, yyyy').format(targetDateTime)
        : 'No target date';

    final now = DateTime.now();
    final monthlyNeed = goalMonthlyNeed(goal);
    final double dailySetAside;
    if (remaining <= 0) {
      dailySetAside = 0;
    } else if (targetDateTime != null) {
      final daysRemaining = targetDateTime.difference(now).inDays;
      dailySetAside = daysRemaining > 0 ? remaining / daysRemaining : remaining;
    } else {
      dailySetAside = monthlyNeed / 30;
    }

    final bool? canAfford = goal.canAffordByTargetDate;
    final String? statusLabel = canAfford == null
        ? null
        : (canAfford ? 'On track' : 'Behind schedule');
    final statusColor = canAfford == true
        ? DashboardTokens.bermuda
        : DashboardTokens.apricot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Goal Progress Hero Card (Node 11:1902) ──────────────
        KasyabaCard(
          variant: KasyabaCardVariant.hero,
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    CurrencyFormatter.format(
                      goal.currentAmount,
                      decimalDigits: 0,
                    ),
                    style: GoogleFonts.bricolageGrotesque(
                      color: DashboardTokens.periwinkleGray,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: GoogleFonts.bricolageGrotesque(
                      color: DashboardTokens.periwinkleGray,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'of ${CurrencyFormatter.format(goal.targetAmount, decimalDigits: 0)} target',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGraySubtitle,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 8,
                  width: double.infinity,
                  color: DashboardTokens.poloBlue.withValues(alpha: 0.2),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: goal.progress.clamp(0.0, 1.0),
                    child: const ColoredBox(color: DashboardTokens.bermuda),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // On track / behind schedule badge
              if (statusLabel != null) ...[
                Text(
                  '$statusLabel · $targetDateStr',
                  style: GoogleFonts.dmSans(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                'Needs about ${CurrencyFormatter.format(monthlyNeed, decimalDigits: 0)} a month',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGraySubtitle,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Details Section Header (Node 11:1915) ────────────────
        Text(
          'Details',
          style: GoogleFonts.bricolageGrotesque(
            color: DashboardTokens.periwinkleGray,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // ── Details Card (Node 11:1917) ──────────────────────────
        KasyabaCard(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
          child: Column(
            children: [
              _DetailRow(
                label: 'Remaining',
                value: CurrencyFormatter.format(remaining, decimalDigits: 0),
              ),
              const Divider(color: DashboardTokens.poloBlue16, height: 16),
              _DetailRow(label: 'Target date', value: targetDateStr),
              const Divider(color: DashboardTokens.poloBlue16, height: 16),
              _DetailRow(
                label: 'Set aside each day',
                value: CurrencyFormatter.format(dailySetAside),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Deposits Section Header (Node 11:1939) ───────────────
        Text(
          'Deposits',
          style: GoogleFonts.bricolageGrotesque(
            color: DashboardTokens.periwinkleGray,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),

        // ── Deposits Card (Node 11:1941) ─────────────────────────
        _buildDeposits(detailAsync),
        const SizedBox(height: 24),

        // ── Action Button 1: Deposit (Node 11:1947) ──────────────
        PillButton(
          label: 'Deposit',
          onPressed: () {
            AppHaptics.selectionClick();
            showGoalDepositSheet(context, goal);
          },
        ),
        const SizedBox(height: 12),

        // ── Action Button 2: Edit goal (Node 11:1949) ────────────
        PillButton(
          label: 'Edit goal',
          variant: PillButtonVariant.secondary,
          onPressed: () {
            AppHaptics.selectionClick();
            context.push('/goals/new', extra: goal);
          },
        ),
        const SizedBox(height: 8),

        // ── Action Button 3: Delete goal (Node 11:1951) ──────────
        Center(
          child: TextButton(
            onPressed: _isDeleting ? null : () => _handleDelete(goal),
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: DashboardTokens.apricot,
                    ),
                  )
                : Text(
                    'Delete goal',
                    style: GoogleFonts.dmSans(
                      color: DashboardTokens.apricot,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeposits(AsyncValue<Map<String, dynamic>> detailAsync) {
    if (detailAsync.isLoading) {
      return const KasyabaLoadingSkeleton(lines: 2);
    }

    if (detailAsync.hasError) {
      return KasyabaErrorCard(
        message: friendlyErrorMessage(
          detailAsync.error,
          fallback: 'Could not load deposits.',
        ),
        onRetry: () => ref.invalidate(goalDetailProvider(widget.goalId)),
      );
    }

    final detailData = detailAsync.valueOrNull;
    final contributionsList =
        detailData != null && detailData['contributions'] is List
        ? detailData['contributions'] as List<dynamic>
        : const <dynamic>[];

    if (contributionsList.isEmpty) {
      return KasyabaCard(
        padding: EdgeInsets.zero,
        child: KasyabaEmptyState(
          icon: Icons.savings_outlined,
          title: 'No deposits yet',
          message: 'Deposits toward this goal will appear here.',
        ),
      );
    }

    return KasyabaCard(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
      child: Column(
        children: contributionsList.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value as Map<String, dynamic>;
          final amount =
              double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
          final dateRaw = item['contributedAt']?.toString();
          final dt = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
          final dateFmt = dt != null
              ? DateFormat('MMM d, yyyy').format(dt)
              : 'Unknown date';

          return Column(
            children: [
              if (idx > 0)
                const Divider(color: DashboardTokens.poloBlue16, height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFmt,
                    style: GoogleFonts.dmSans(
                      color: DashboardTokens.periwinkleGraySubtitle,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '+${CurrencyFormatter.format(amount, decimalDigits: 0)}',
                    style: GoogleFonts.dmSans(
                      color: DashboardTokens.bermuda,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: DashboardTokens.periwinkleGraySubtitle,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: DashboardTokens.periwinkleGray,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
