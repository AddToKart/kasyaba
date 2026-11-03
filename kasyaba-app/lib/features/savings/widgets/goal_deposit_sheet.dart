import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Goal Deposit Modal (Figma Node 42:6619)
/// ─────────────────────────────────────────────────────────────
void showGoalDepositSheet(BuildContext context, SavingsGoal goal) {
  final topPadding = MediaQuery.paddingOf(context).top;
  final screenHeight = MediaQuery.sizeOf(context).height;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    constraints: BoxConstraints(maxHeight: screenHeight - topPadding - 32),
    builder: (ctx) => _GoalDepositModal(goal: goal),
  );
}

class GoalDepositSheet {
  static void show(BuildContext context, SavingsGoal goal) {
    showGoalDepositSheet(context, goal);
  }
}

class _GoalDepositModal extends ConsumerStatefulWidget {
  final SavingsGoal goal;

  const _GoalDepositModal({required this.goal});

  @override
  ConsumerState<_GoalDepositModal> createState() => _GoalDepositModalState();
}

class _GoalDepositModalState extends ConsumerState<_GoalDepositModal> {
  final _amountController = TextEditingController(text: '5000');
  String? _selectedAccountId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
  }

  Future<void> _handleSaveDeposit() async {
    final amount = _enteredAmount;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid deposit amount');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      AppHaptics.mediumImpact();
      await ref.read(budgetRepositoryProvider).addGoalContribution(
            goalId: widget.goal.id,
            amount: amount,
            accountId: _selectedAccountId,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: DashboardTokens.bigStone,
            content: Text(
              'Deposited ${CurrencyFormatter.format(amount)} to ${widget.goal.name}!',
              style: GoogleFonts.dmSans(
                color: DashboardTokens.bermuda,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to deposit: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxAllowedHeight = screenHeight - topPadding - 32;

    // Calibrated clearance so CTA button sits cleanly above the persistent floating dock
    const dockClearance = 105.0;
    final effectiveBottomPadding = bottomInset > 0
        ? (bottomInset + 20.0)
        : dockClearance;

    final accounts = accountsAsync.valueOrNull ?? [];
    if (_selectedAccountId == null && accounts.isNotEmpty) {
      _selectedAccountId = accounts.first.id;
    }

    final selectedAccount = accounts.firstWhere(
      (a) => a.id == _selectedAccountId,
      orElse: () => accounts.isNotEmpty
          ? accounts.first
          : const Account(
              id: 'cash_wallet',
              name: 'Cash Wallet',
              type: 'cash',
            ),
    );

    final balances = balancesAsync.valueOrNull ?? {};
    final selectedBalance = balances[selectedAccount.id] ?? 825149.80;

    final depositAmt = _enteredAmount;
    final projectedCurrent = widget.goal.currentAmount + depositAmt;
    final projectedPercent = widget.goal.targetAmount > 0
        ? ((projectedCurrent / widget.goal.targetAmount) * 100).clamp(0, 100).toInt()
        : 0;

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxAllowedHeight),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            border: Border(
              top: BorderSide(color: DashboardTokens.poloBlue30, width: 1.0),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Fixed Top Pinned Drag Handle ─────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 8),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: DashboardTokens.poloBlue.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              // ── Scrollable Modal Content ─────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, effectiveBottomPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Text(
                        'Deposit to ${widget.goal.name}',
                        style: GoogleFonts.bricolageGrotesque(
                          color: DashboardTokens.periwinkleGray,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Amount Display & Seamless Input ──────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₱',
                              style: GoogleFonts.bricolageGrotesque(
                                color: DashboardTokens.periwinkleGraySubtitle,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IntrinsicWidth(
                              child: TextField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                autofocus: true,
                                onChanged: (_) => setState(() {}),
                                style: GoogleFonts.bricolageGrotesque(
                                  color: DashboardTokens.periwinkleGray,
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  filled: false,
                                  fillColor: Colors.transparent,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Projected Impact Subtitle ────────────────────────
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                              color: DashboardTokens.periwinkleGraySubtitle,
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: '${widget.goal.name}: ${CurrencyFormatter.format(widget.goal.currentAmount, decimalDigits: 0)} → ',
                              ),
                              TextSpan(
                                text: '${CurrencyFormatter.format(projectedCurrent, decimalDigits: 0)} ($projectedPercent%)',
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.bermuda,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ── From Wallet Card (Node 11:1881) ──────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 18.5),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: DashboardTokens.poloBlue22),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 72,
                              child: Text(
                                'From',
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                selectedAccount.name,
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.periwinkleGray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(selectedBalance),
                              style: GoogleFonts.dmSans(
                                color: DashboardTokens.periwinkleGraySubtitle,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Explanatory Note ─────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'This money is set aside for the goal and comes out of your safe-to-spend.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: DashboardTokens.periwinkleGraySubtitle,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: DashboardTokens.apricot,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // ── CTA Button ───────────────────────────────────────
                      SizedBox(
                        height: 56,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _handleSaveDeposit,
                          style: FilledButton.styleFrom(
                            backgroundColor: DashboardTokens.periwinkleGray,
                            foregroundColor: DashboardTokens.ebony,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: DashboardTokens.ebony,
                                  ),
                                )
                              : Text(
                                  'Save deposit',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
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
}
