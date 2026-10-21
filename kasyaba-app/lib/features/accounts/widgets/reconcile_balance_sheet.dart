import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/pressable_scale.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';

/// Shows the 1-Tap Wallet Balance Reconciliation modal sheet.
Future<void> showReconcileBalanceSheet(
  BuildContext context, {
  Account? targetAccount,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
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
        // App has more recorded than reality -> Log unaccounted expense
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
        // Reality has more than app recorded -> Log unaccounted income
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${account.name} reconciled to $formattedActual (${discrepancy < 0 ? '-' : '+'}${CurrencyFormatter.format(discrepancy.abs())} logged)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.emerald600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                error,
                fallback: 'Could not reconcile balance. Please try again.',
              ),
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final balances = balancesAsync.valueOrNull ?? const <String, double>{};

    return accountsAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface900 : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface900 : AppColors.lightCard,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Text(
          friendlyErrorMessage(error, fallback: 'Could not load accounts.'),
          style: const TextStyle(color: AppColors.expense),
        ),
      ),
      data: (accounts) {
        if (accounts.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface900 : AppColors.lightCard,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Text('No accounts available to reconcile.'),
          );
        }

        final selected = _selectedAccount != null &&
                accounts.any((a) => a.id == _selectedAccount!.id)
            ? accounts.firstWhere((a) => a.id == _selectedAccount!.id)
            : accounts.first;

        final recordedBalance = balances[selected.id] ?? 0.0;
        final rawInput = _actualBalanceController.text.trim();
        final actualBalance = double.tryParse(rawInput);
        final hasInput = rawInput.isNotEmpty && actualBalance != null;
        final discrepancy = hasInput ? (actualBalance - recordedBalance) : null;

        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.92,
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 +
                    MediaQuery.viewInsetsOf(context).bottom +
                    MediaQuery.paddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surface900.withValues(alpha: 0.95)
                    : AppColors.lightCard.withValues(alpha: 0.98),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : AppColors.lightBorder,
                  width: 1,
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Drag Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surface600
                                : AppColors.lightBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Header
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.emerald500
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.emerald500
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Icon(
                              Icons.tune_rounded,
                              color: AppColors.emerald400,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Reconcile Balance',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textLight,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.emerald500
                                            .withValues(alpha: 0.16),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'QUICK AUDIT',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.emerald400,
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Align recorded ledger with actual physical cash or bank',
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
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedL,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Account Switcher (if > 1 accounts)
                      if (accounts.length > 1) ...[
                        Text(
                          'SELECT WALLET TO RECONCILE',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedL,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surface800
                                : AppColors.lightCard2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surface700
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Account>(
                              value: selected,
                              isExpanded: true,
                              dropdownColor: isDark
                                  ? AppColors.surface800
                                  : AppColors.lightCard,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedL,
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
                                        color: AppColors.emerald400,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          acc.name,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? AppColors.textDark
                                                : AppColors.textLight,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        CurrencyFormatter.format(accBal),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          fontFeatures:
                                              CurrencyFormatter.tabularFigures,
                                          color: isDark
                                              ? AppColors.textMuted
                                              : AppColors.textMutedL,
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

                      // Recorded App Balance Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surface800
                              : AppColors.lightCard2,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.07)
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECORDED APP BALANCE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.textMutedL,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  CurrencyFormatter.format(recordedBalance),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    fontFeatures:
                                        CurrencyFormatter.tabularFigures,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surface700
                                    : AppColors.lightCard,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.surface600
                                      : AppColors.lightBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _iconForType(selected.type),
                                    size: 14,
                                    color: AppColors.emerald400,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    selected.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textDark
                                          : AppColors.textLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actual Real-World Balance Input
                      Text(
                        'ACTUAL REAL-WORLD BALANCE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textMutedL,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _actualBalanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          fontFeatures: CurrencyFormatter.tabularFigures,
                          color: isDark ? Colors.white : AppColors.textLight,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 6),
                            child: Text(
                              '₱',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald400,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 0,
                          ),
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.25)
                                : AppColors.textMutedL.withValues(alpha: 0.5),
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppColors.surface800
                              : AppColors.lightCard2,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.surface700
                                  : AppColors.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark
                                  ? AppColors.surface700
                                  : AppColors.lightBorder,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.emerald500,
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

                      // Deterministic Discrepancy Card
                      if (discrepancy == null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surface800
                                : AppColors.lightCard2,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.subtleBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedL,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Enter your actual physical cash or bank balance to calculate discrepancy.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.textMutedL,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (discrepancy.abs() < 0.005)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                AppColors.emerald500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.emerald500
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: AppColors.emerald400,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'In Perfect Sync (₱0.00 discrepancy)',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.emerald400,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Recorded app balance matches your physical wallet exactly.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: discrepancy < 0
                                ? AppColors.expense.withValues(alpha: 0.12)
                                : AppColors.emerald500
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: discrepancy < 0
                                  ? AppColors.expense.withValues(alpha: 0.4)
                                  : AppColors.emerald500
                                      .withValues(alpha: 0.4),
                              width: 1.2,
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
                                        ? const Color(0xFFF87171)
                                        : AppColors.emerald400,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    discrepancy < 0
                                        ? 'Discrepancy: -${CurrencyFormatter.format(discrepancy.abs())}'
                                        : 'Discrepancy: +${CurrencyFormatter.format(discrepancy)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures:
                                          CurrencyFormatter.tabularFigures,
                                      color: discrepancy < 0
                                          ? const Color(0xFFF87171)
                                          : AppColors.emerald400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                discrepancy < 0
                                    ? 'App shows ${CurrencyFormatter.format(discrepancy.abs())} more than reality. Tapping sync will log an Unaccounted Expense adjustment so the ledger history stays 100% mathematically sound.'
                                    : 'You have ${CurrencyFormatter.format(discrepancy)} more in reality than recorded in app. Tapping sync will log an Unaccounted Income adjustment so the ledger history stays 100% mathematically sound.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  height: 1.35,
                                  color: isDark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 18),

                      // Primary Action CTA
                      PressableScale(
                        onTap: (_isSubmitting ||
                                discrepancy == null ||
                                discrepancy.abs() < 0.005)
                            ? null
                            : () {
                                AppHaptics.mediumImpact();
                                _handleSync(
                                  selected,
                                  recordedBalance,
                                  actualBalance!,
                                  discrepancy,
                                );
                              },
                        child: ElevatedButton(
                          onPressed: (_isSubmitting ||
                                  discrepancy == null ||
                                  discrepancy.abs() < 0.005)
                              ? null
                              : () {
                                  AppHaptics.mediumImpact();
                                  _handleSync(
                                    selected,
                                    recordedBalance,
                                    actualBalance!,
                                    discrepancy,
                                  );
                                },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald500,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: isDark
                              ? AppColors.surface700
                              : AppColors.lightCard2,
                          disabledForegroundColor: AppColors.textMuted,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                discrepancy != null &&
                                        discrepancy.abs() < 0.005
                                    ? 'Balances Already Match'
                                    : 'Sync & Log Adjustment',
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                ),
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
