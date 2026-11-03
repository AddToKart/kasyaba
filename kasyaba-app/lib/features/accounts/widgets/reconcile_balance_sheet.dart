import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/pill_button.dart';

/// Shows the 1-Tap Wallet Balance Reconciliation modal sheet.
Future<void> showReconcileBalanceSheet(
  BuildContext context, {
  Account? targetAccount,
}) {
  return showKasyabaSheet(
    context: context,
    builder: (ctx) => ReconcileBalanceSheet(initialAccount: targetAccount),
  );
}

class ReconcileBalanceSheet extends ConsumerStatefulWidget {
  final Account? initialAccount;

  const ReconcileBalanceSheet({super.key, this.initialAccount});

  @override
  ConsumerState<ReconcileBalanceSheet> createState() =>
      _ReconcileBalanceSheetState();
}

class _ReconcileBalanceSheetState extends ConsumerState<ReconcileBalanceSheet> {
  final _actualBalanceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Account? _selectedAccount;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.initialAccount;
    _actualBalanceController.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _actualBalanceController.removeListener(_onInputChanged);
    _actualBalanceController.dispose();
    super.dispose();
  }

  Future<void> _handleSync(
    Account account,
    double recordedBalance,
    double actualBalance,
    double discrepancy,
  ) async {
    if (!_formKey.currentState!.validate()) return;
    if (discrepancy.abs() < 0.005) return;

    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final formattedRecorded = CurrencyFormatter.format(recordedBalance);
    final formattedActual = CurrencyFormatter.format(actualBalance);

    try {
      final mutator = ref.read(transactionMutatorProvider);

      if (discrepancy < 0) {
        await mutator.addExpense(
          accountId: account.id,
          categoryId: 'cat_other',
          categoryName: 'Balance Adjustment',
          amount: discrepancy.abs(),
          description: 'Balance Adjustment (Unaccounted)',
          spentAt: now,
          notes: 'Reconciled from $formattedRecorded to $formattedActual',
        );
      } else {
        await mutator.addIncome(
          accountId: account.id,
          amount: discrepancy,
          source: 'Balance Adjustment (Unaccounted)',
          receivedAt: now,
          notes: 'Reconciled from $formattedRecorded to $formattedActual',
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        KasyabaToast.showSuccess(
          context,
          '${account.name} reconciled to $formattedActual',
          subtitle:
              '${discrepancy < 0 ? '-' : '+'}${CurrencyFormatter.format(discrepancy.abs())} logged',
        );
      }
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Could not reconcile balance. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  IconData _iconForType(String type) {
    return switch (type) {
      'bank' => Icons.account_balance_rounded,
      'ewallet' => Icons.phone_android_rounded,
      'other' => Icons.wallet_rounded,
      _ => Icons.payments_rounded,
    };
  }

  EdgeInsets _sheetPadding(BuildContext context, {double bottom = 20}) {
    return EdgeInsets.fromLTRB(
      20,
      0,
      20,
      bottom +
          MediaQuery.viewInsetsOf(context).bottom +
          MediaQuery.paddingOf(context).bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final balances = balancesAsync.valueOrNull ?? const <String, double>{};

    return accountsAsync.when(
      loading: () => AppSheet(
        color: KasyabaTokens.ebony,
        padding: _sheetPadding(context),
        child: const KasyabaLoadingSkeleton(lines: 5),
      ),
      error: (error, _) => AppSheet(
        color: KasyabaTokens.ebony,
        padding: _sheetPadding(context),
        child: KasyabaErrorCard(
          message: friendlyErrorMessage(
            error,
            fallback: 'Could not load accounts.',
          ),
          onRetry: () {
            ref.invalidate(accountsProvider);
            ref.invalidate(accountBalancesProvider);
          },
        ),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return AppSheet(
            color: KasyabaTokens.ebony,
            padding: _sheetPadding(context),
            child: const KasyabaEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No accounts to reconcile',
              message: 'Add an account first, then come back to audit it.',
            ),
          );
        }

        final selected =
            _selectedAccount != null &&
                accounts.any((a) => a.id == _selectedAccount!.id)
            ? accounts.firstWhere((a) => a.id == _selectedAccount!.id)
            : accounts.first;

        final recordedBalance = balances[selected.id] ?? 0.0;
        final rawInput = _actualBalanceController.text.trim();
        final actualBalance = double.tryParse(rawInput);
        final hasInput = rawInput.isNotEmpty && actualBalance != null;
        final discrepancy = hasInput ? (actualBalance - recordedBalance) : null;
        final canSync =
            !_isSubmitting && discrepancy != null && discrepancy.abs() >= 0.005;

        return AppSheet(
          color: KasyabaTokens.ebony,
          padding: _sheetPadding(context),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.84,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: KasyabaTokens.bermuda15,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: KasyabaTokens.bermuda.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: const Icon(
                            Icons.tune_rounded,
                            color: KasyabaTokens.bermuda,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Reconcile Balance',
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: KasyabaTokens.periwinkleGray,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: KasyabaTokens.bermuda15,
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    child: Text(
                                      'QUICK AUDIT',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: KasyabaTokens.bermuda,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Align recorded ledger with actual physical cash or bank',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  color: KasyabaTokens.periwinkleGraySubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: KasyabaTokens.periwinkleGraySubtitle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (accounts.length > 1) ...[
                      _sectionLabel('SELECT WALLET TO RECONCILE'),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: KasyabaTokens.bigStone,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: KasyabaTokens.poloBlue22),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<Account>(
                            value: selected,
                            isExpanded: true,
                            dropdownColor: KasyabaTokens.bigStone,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: KasyabaTokens.periwinkleGraySubtitle,
                            ),
                            items: accounts.map((acc) {
                              final accBal = balances[acc.id] ?? 0.0;
                              return DropdownMenuItem<Account>(
                                value: acc,
                                child: Row(
                                  children: [
                                    Icon(
                                      _iconForType(acc.type),
                                      size: 16,
                                      color: KasyabaTokens.bermuda,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        acc.name,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: KasyabaTokens.periwinkleGray,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      CurrencyFormatter.format(accBal),
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures:
                                            CurrencyFormatter.tabularFigures,
                                        color: KasyabaTokens
                                            .periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (newAcc) {
                              if (newAcc != null) {
                                setState(() => _selectedAccount = newAcc);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KasyabaTokens.bigStone,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: KasyabaTokens.poloBlue22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionLabel('RECORDED APP BALANCE'),
                              const SizedBox(height: 4),
                              Text(
                                CurrencyFormatter.format(recordedBalance),
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  fontFeatures:
                                      CurrencyFormatter.tabularFigures,
                                  color: KasyabaTokens.periwinkleGray,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: KasyabaTokens.ebony,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: KasyabaTokens.poloBlue22,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _iconForType(selected.type),
                                  size: 14,
                                  color: KasyabaTokens.bermuda,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  selected.name,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: KasyabaTokens.periwinkleGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionLabel('ACTUAL REAL-WORLD BALANCE'),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _actualBalanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      autofocus: true,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        fontFeatures: CurrencyFormatter.tabularFigures,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 6),
                          child: Text(
                            '₱',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: KasyabaTokens.bermuda,
                              fontFeatures: CurrencyFormatter.tabularFigures,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 0,
                        ),
                        hintText: '0.00',
                        hintStyle: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: KasyabaTokens.poloBlue40,
                          fontFeatures: CurrencyFormatter.tabularFigures,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        filled: true,
                        fillColor: KasyabaTokens.bigStone,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: KasyabaTokens.poloBlue22,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: KasyabaTokens.poloBlue22,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: KasyabaTokens.poloBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your actual real-world balance';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || !parsed.isFinite) {
                          return 'Enter a valid monetary amount';
                        }
                        if (parsed < 0) {
                          return 'Balance cannot be negative';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    if (discrepancy == null)
                      _InfoCard(
                        background: KasyabaTokens.bigStone,
                        border: KasyabaTokens.poloBlue22,
                        icon: Icons.info_outline_rounded,
                        iconColor: KasyabaTokens.periwinkleGraySubtitle,
                        title: null,
                        titleColor: KasyabaTokens.periwinkleGray,
                        message:
                            'Enter your actual physical cash or bank balance to calculate discrepancy.',
                        messageColor: KasyabaTokens.periwinkleGraySubtitle,
                      )
                    else if (discrepancy.abs() < 0.005)
                      const _InfoCard(
                        background: KasyabaTokens.bermuda15,
                        border: KasyabaTokens.bermuda,
                        icon: Icons.check_circle_rounded,
                        iconColor: KasyabaTokens.bermuda,
                        title: 'In Perfect Sync (₱0.00 discrepancy)',
                        titleColor: KasyabaTokens.bermuda,
                        message:
                            'Recorded app balance matches your physical wallet exactly.',
                        messageColor: KasyabaTokens.periwinkleGraySubtitle,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: discrepancy < 0
                              ? KasyabaTokens.apricot15
                              : KasyabaTokens.bermuda15,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: discrepancy < 0
                                ? KasyabaTokens.apricot.withValues(alpha: 0.55)
                                : KasyabaTokens.bermuda.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  discrepancy < 0
                                      ? Icons.trending_down_rounded
                                      : Icons.trending_up_rounded,
                                  size: 18,
                                  color: discrepancy < 0
                                      ? KasyabaTokens.apricot
                                      : KasyabaTokens.bermuda,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    discrepancy < 0
                                        ? 'Discrepancy: -${CurrencyFormatter.format(discrepancy.abs())}'
                                        : 'Discrepancy: +${CurrencyFormatter.format(discrepancy)}',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFeatures:
                                          CurrencyFormatter.tabularFigures,
                                      color: discrepancy < 0
                                          ? KasyabaTokens.apricot
                                          : KasyabaTokens.bermuda,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              discrepancy < 0
                                  ? 'App shows ${CurrencyFormatter.format(discrepancy.abs())} more than reality. Tapping sync will log an Unaccounted Expense adjustment so the ledger history stays 100% mathematically sound.'
                                  : 'You have ${CurrencyFormatter.format(discrepancy)} more in reality than recorded in app. Tapping sync will log an Unaccounted Income adjustment so the ledger history stays 100% mathematically sound.',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                height: 1.4,
                                color: KasyabaTokens.periwinkleGraySubtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 18),
                    PillButton(
                      label: discrepancy != null && discrepancy.abs() < 0.005
                          ? 'Balances Already Match'
                          : 'Sync & Log Adjustment',
                      isLoading: _isSubmitting,
                      onPressed: canSync
                          ? () {
                              AppHaptics.mediumImpact();
                              _handleSync(
                                selected,
                                recordedBalance,
                                actualBalance!,
                                discrepancy,
                              );
                            }
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: KasyabaTokens.periwinkleGraySubtitle,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Color background;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String? title;
  final Color titleColor;
  final String message;
  final Color messageColor;

  const _InfoCard({
    required this.background,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.message,
    required this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    color: messageColor,
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
