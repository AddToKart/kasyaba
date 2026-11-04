import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Goal Deposit Modal (Figma Node 42:6619)
/// ─────────────────────────────────────────────────────────────
void showGoalDepositSheet(BuildContext context, SavingsGoal goal) {
  showKasyabaSheet<void>(
    context: context,
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
  final _amountController = TextEditingController();
  String? _selectedAccountId;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _enteredAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
  }

  String? _effectiveAccountId(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    for (final account in accounts) {
      if (account.id == _selectedAccountId) return account.id;
    }
    return accounts.first.id;
  }

  Future<void> _handleSaveDeposit() async {
    final amount = _enteredAmount;
    if (amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid deposit amount');
      return;
    }

    final accounts =
        ref.read(accountsProvider).valueOrNull ?? const <Account>[];
    final accountId = _effectiveAccountId(accounts);
    if (accountId == null) {
      setState(() => _errorMessage = 'No wallets available yet');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      AppHaptics.mediumImpact();
      await ref
          .read(budgetRepositoryProvider)
          .addGoalContribution(
            goalId: widget.goal.id,
            amount: amount,
            accountId: accountId,
          );
      if (mounted) {
        // Toast first: this sheet's context unmounts right after the pop.
        KasyabaToast.showSuccess(
          context,
          'Deposited ${CurrencyFormatter.format(amount)}',
          subtitle: 'Added to ${widget.goal.name}',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = friendlyErrorMessage(
            e,
            fallback: 'Could not save your deposit. Please try again.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // Calibrated clearance so CTA button sits cleanly above the floating dock
    final effectiveBottomPadding = bottomInset > 0
        ? (bottomInset + 20.0)
        : DashboardTokens.dockClearance;

    final accounts = accountsAsync.valueOrNull ?? const <Account>[];
    final effectiveAccountId = _effectiveAccountId(accounts);
    Account? selectedAccount;
    for (final account in accounts) {
      if (account.id == effectiveAccountId) {
        selectedAccount = account;
        break;
      }
    }

    final balances = balancesAsync.valueOrNull ?? const <String, double>{};
    final selectedBalance = selectedAccount != null
        ? balances[selectedAccount.id]
        : null;
    final walletUnavailableMessage = accountsAsync.hasError
        ? friendlyErrorMessage(
            accountsAsync.error,
            fallback: 'Could not load your wallets.',
          )
        : 'No wallets available yet';
    final canSubmit = !_isSubmitting && selectedAccount != null;

    final depositAmt = _enteredAmount;
    final projectedCurrent = widget.goal.currentAmount + depositAmt;
    final projectedPercent = widget.goal.targetAmount > 0
        ? ((projectedCurrent / widget.goal.targetAmount) * 100)
              .clamp(0, 100)
              .toInt()
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
      child: AppSheet(
        color: DashboardTokens.bigStone,
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
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
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
                                text:
                                    '${widget.goal.name}: ${CurrencyFormatter.format(widget.goal.currentAmount, decimalDigits: 0)} → ',
                              ),
                              TextSpan(
                                text:
                                    '${CurrencyFormatter.format(projectedCurrent, decimalDigits: 0)} ($projectedPercent%)',
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 21,
                          vertical: 18.5,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: DashboardTokens.poloBlue22),
                        ),
                        child: selectedAccount != null
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      'From',
                                      style: GoogleFonts.dmSans(
                                        color: DashboardTokens
                                            .periwinkleGraySubtitle,
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
                                    selectedBalance != null
                                        ? CurrencyFormatter.format(
                                            selectedBalance,
                                          )
                                        : '—',
                                    style: GoogleFonts.dmSans(
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                walletUnavailableMessage,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  color: accountsAsync.hasError
                                      ? DashboardTokens.apricot
                                      : DashboardTokens.periwinkleGraySubtitle,
                                  fontSize: 14,
                                ),
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
                      PillButton(
                        label: 'Save deposit',
                        onPressed: canSubmit ? _handleSaveDeposit : null,
                        isLoading: _isSubmitting,
                      ),
          ],
        ),
      ),
    );
  }
}
