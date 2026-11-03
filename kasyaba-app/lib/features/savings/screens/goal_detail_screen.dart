import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../widgets/goal_deposit_sheet.dart';
import 'create_goal_screen.dart';

/// ─────────────────────────────────────────────────────────────
///  Goal Detail Screen (Figma Node 42:6692 — "tap a goal")
/// ─────────────────────────────────────────────────────────────
class GoalDetailScreen extends ConsumerStatefulWidget {
  final String goalId;
  final SavingsGoal? initialGoal;

  const GoalDetailScreen({
    super.key,
    required this.goalId,
    this.initialGoal,
  });

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  bool _isDeleting = false;

  Future<void> _handleDelete(SavingsGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DashboardTokens.bigStone,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete ${goal.name}?',
          style: GoogleFonts.bricolageGrotesque(
            color: DashboardTokens.periwinkleGray,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will delete the goal and its deposit tracking history. Your wallet balances remain untouched.',
          style: GoogleFonts.dmSans(
            color: DashboardTokens.periwinkleGraySubtitle,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.dmSans(color: DashboardTokens.periwinkleGraySubtitle),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DashboardTokens.apricot,
              foregroundColor: DashboardTokens.ebony,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        AppHaptics.mediumImpact();
        await ref.read(budgetRepositoryProvider).deleteGoal(widget.goalId);
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: DashboardTokens.apricot,
              content: Text(
                'Failed to delete goal: $e',
                style: GoogleFonts.dmSans(color: DashboardTokens.ebony),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final goalsAsync = ref.watch(goalsProvider);
    final detailAsync = ref.watch(goalDetailProvider(widget.goalId));

    // Match live goal from goalsProvider or fallback to initialGoal
    final liveGoal = goalsAsync.valueOrNull?.firstWhere(
      (g) => g.id == widget.goalId,
      orElse: () => widget.initialGoal ?? SavingsGoal(
        id: widget.goalId,
        name: 'Savings Goal',
        targetAmount: 50000,
        currentAmount: 10000,
      ),
    ) ?? widget.initialGoal ?? SavingsGoal(
      id: widget.goalId,
      name: 'Savings Goal',
      targetAmount: 50000,
      currentAmount: 10000,
    );

    final goal = liveGoal;
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
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
    final daysRemaining = targetDateTime != null
        ? targetDateTime.difference(now).inDays.clamp(1, 9999)
        : 365;

    final dailySetAside = remaining > 0 ? (remaining / daysRemaining) : 0.0;
    final monthlyNeed = goal.monthlySavingsRequired ?? (dailySetAside * 30.0);

    // Extract contributions from detailAsync
    final detailData = detailAsync.valueOrNull;
    final contributionsList = detailData != null && detailData['contributions'] is List
        ? (detailData['contributions'] as List<dynamic>)
        : [];

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: DashboardTokens.ebony,
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Header (Node 11:1896) ──────────────────────────
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.selectionClick();
                      Navigator.of(context).pop();
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
                      goal.name,
                      style: GoogleFonts.bricolageGrotesque(
                        color: DashboardTokens.periwinkleGray,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Goal Progress Hero Card (Node 11:1902) ──────────────
              Container(
                padding: const EdgeInsets.all(21),
                decoration: BoxDecoration(
                  color: DashboardTokens.cello60,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DashboardTokens.poloBlue30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.format(goal.currentAmount, decimalDigits: 0),
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
                          widthFactor: (goal.progress).clamp(0.0, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: DashboardTokens.bermuda,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // On track badge
                    Text(
                      'On track · $targetDateStr',
                      style: GoogleFonts.dmSans(
                        color: DashboardTokens.bermuda,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
                decoration: BoxDecoration(
                  color: DashboardTokens.bigStone,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Column(
                  children: [
                    _DetailRow(
                      label: 'Remaining',
                      value: CurrencyFormatter.format(remaining, decimalDigits: 0),
                    ),
                    const Divider(color: DashboardTokens.poloBlue16, height: 16),
                    _DetailRow(
                      label: 'Target date',
                      value: targetDateStr,
                    ),
                    const Divider(color: DashboardTokens.poloBlue16, height: 16),
                    _DetailRow(
                      label: 'Set aside each day',
                      value: CurrencyFormatter.format(dailySetAside),
                    ),
                    const Divider(color: DashboardTokens.poloBlue16, height: 16),
                    const _DetailRow(
                      label: 'Counts toward',
                      value: 'Safe to spend',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
                decoration: BoxDecoration(
                  color: DashboardTokens.bigStone,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: contributionsList.isNotEmpty
                    ? Column(
                        children: contributionsList.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final item = entry.value as Map<String, dynamic>;
                          final amount = double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
                          final dateRaw = item['contributedAt']?.toString();
                          final dt = dateRaw != null ? DateTime.tryParse(dateRaw) : null;
                          final dateFmt = dt != null ? DateFormat('MMM d, yyyy').format(dt) : 'Recent';

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
                      )
                    : goal.currentAmount > 0
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Initial balance',
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '+${CurrencyFormatter.format(goal.currentAmount, decimalDigits: 0)}',
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.bermuda,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No deposits recorded yet.',
                              style: GoogleFonts.dmSans(
                                color: DashboardTokens.periwinkleGraySubtitle,
                                fontSize: 14,
                              ),
                            ),
                          ),
              ),
              const SizedBox(height: 24),

              // ── Action Button 1: Deposit (Node 11:1947) ──────────────
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    AppHaptics.selectionClick();
                    showGoalDepositSheet(context, goal);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardTokens.periwinkleGray,
                    foregroundColor: DashboardTokens.ebony,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Deposit',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Action Button 2: Edit goal (Node 11:1949) ────────────
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () {
                    AppHaptics.selectionClick();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CreateGoalScreen(existingGoal: goal),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DashboardTokens.periwinkleGray,
                    side: const BorderSide(color: DashboardTokens.kashmirBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'Edit goal',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
          ),
        ),
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
