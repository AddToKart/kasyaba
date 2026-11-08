import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/cache_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/preference_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validated_input.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/figma_toggle_switch.dart';
import '../../../shared/widgets/kasyaba_background.dart';
import '../../../shared/widgets/kasyaba_card.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';
import '../widgets/reconcile_balance_sheet.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  Future<void> _showAddAccountSheet(BuildContext context) async {
    final created = await showKasyabaSheet<bool>(
      context: context,
      builder: (_) => const _AddAccountSheet(),
    );
    if (created == true && context.mounted) {
      KasyabaToast.showSuccess(context, 'Account created.');
    }
  }

  Future<void> _archiveAccount(
    BuildContext context,
    WidgetRef ref,
    Account account,
    int accountCount,
  ) async {
    if (!ref.read(isOnlineProvider)) {
      KasyabaToast.showInfo(
        context,
        'Archiving accounts needs an internet connection.',
      );
      return;
    }
    if (accountCount <= 1) {
      KasyabaToast.showInfo(context, 'Keep at least one active account.');
      return;
    }

    final confirmed = await showKasyabaConfirmDialog(
      context,
      title: 'Archive ${account.name}?',
      message:
          'It will disappear from new transactions, but its history remains in your financial records.',
      confirmLabel: 'Archive',
      destructive: true,
    );

    if (!context.mounted || confirmed != true) return;

    try {
      await ref.read(transactionMutatorProvider).archiveAccount(account.id);
      if (!context.mounted) return;
      KasyabaToast.showSuccess(context, 'Account archived.');
    } catch (error) {
      if (!context.mounted) return;
      KasyabaToast.showError(
        context,
        friendlyErrorMessage(
          error,
          fallback: 'Could not archive the account. Please try again.',
        ),
      );
    }
  }

  IconData _iconForType(String type) {
    return switch (type.toLowerCase()) {
      'bank' => Icons.account_balance_rounded,
      'ewallet' => Icons.phone_android_rounded,
      'other' => Icons.account_balance_wallet_rounded,
      _ => Icons.payments_rounded,
    };
  }

  String _descriptionForType(String type) {
    return switch (type.toLowerCase()) {
      'bank' => 'Bank account',
      'ewallet' => 'E-wallet',
      'other' => 'Other wallet',
      _ => 'Cash on hand',
    };
  }

  String _balanceLabel(
    AsyncValue<Map<String, double>> balancesAsync,
    String accountId,
  ) {
    final balances = balancesAsync.valueOrNull;
    if (balances == null) return '—';
    final value = balances[accountId];
    if (value == null) return '—';
    return CurrencyFormatter.format(value);
  }

  String _totalLabel(
    List<Account> accounts,
    AsyncValue<Map<String, double>> balancesAsync,
  ) {
    final balances = balancesAsync.valueOrNull;
    if (balances == null) return '—';
    var total = 0.0;
    for (final account in accounts) {
      total += balances[account.id] ?? 0.0;
    }
    return CurrencyFormatter.format(total);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final excludedAccountIds = ref.watch(excludedAccountsProvider);
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: context.kColors.canvas,
      body: KasyabaBackground(
        child: SafeArea(
          bottom: false,
          child: accountsAsync.when(
            loading: () => ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, KasyabaTokens.dockClearance),
              children: const [
                _AccountsHeader(),
                SizedBox(height: 20),
                KasyabaLoadingSkeleton(lines: 5),
              ],
            ),
            error: (error, _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, KasyabaTokens.dockClearance),
              children: [
                const _AccountsHeader(),
                const SizedBox(height: 20),
                KasyabaErrorCard(
                  message: friendlyErrorMessage(
                    error,
                    fallback: 'Could not load your accounts.',
                  ),
                  onRetry: () {
                    ref.invalidate(accountsProvider);
                    ref.invalidate(accountBalancesProvider);
                  },
                ),
              ],
            ),
            data: (accounts) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, KasyabaTokens.dockClearance),
                children: [
                  const _AccountsHeader(),
                  const SizedBox(height: 10),
                  const OfflineStatusBadge(
                    snapshotKey: CacheService.snapshotKeyAccounts,
                  ),
                  const SizedBox(height: 10),
                  if (!isOnline) ...[
                    const NeedsInternetNotice(
                      message:
                          'Adding or archiving accounts needs an internet connection.',
                    ),
                    const SizedBox(height: 14),
                  ],
                  FadeSlideEntrance.staggered(
                    index: 1,
                    child: Container(
                      padding: const EdgeInsets.all(19),
                      decoration: BoxDecoration(
                        color: context.kColors.cardHero,
                        borderRadius: BorderRadius.circular(
                          KasyabaTokens.radiusCard,
                        ),
                        border: Border.all(
                          color: context.kColors.cardBorderStrong,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total across accounts',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: context.kColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _totalLabel(accounts, balancesAsync),
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: context.kColors.textPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (balancesAsync.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: KasyabaErrorCard(
                        message: friendlyErrorMessage(
                          balancesAsync.error,
                          fallback: 'Could not load account balances.',
                        ),
                        onRetry: () => ref.invalidate(accountBalancesProvider),
                      ),
                    ),
                  if (accounts.isEmpty)
                    FadeSlideEntrance.staggered(
                      index: 2,
                      child: KasyabaCard(
                        padding: EdgeInsets.zero,
                        child: KasyabaEmptyState(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'No accounts yet',
                          message:
                              'Add a cash wallet, bank account, or e-wallet to start tracking your money.',
                          action: PillButton(
                            label: 'Add account',
                            onPressed: isOnline
                                ? () => _showAddAccountSheet(context)
                                : null,
                            height: 48,
                            expand: false,
                          ),
                        ),
                      ),
                    )
                  else
                    FadeSlideEntrance.staggered(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 19,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: context.kColors.card,
                          borderRadius: BorderRadius.circular(
                            KasyabaTokens.radiusCard,
                          ),
                          border: Border.all(
                            color: context.kColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            for (int i = 0; i < accounts.length; i++) ...[
                              if (i > 0)
                                Container(
                                  height: 1,
                                  color: context.kColors.divider,
                                ),
                              _buildAccountItem(
                                context,
                                ref,
                                account: accounts[i],
                                balanceLabel: _balanceLabel(
                                  balancesAsync,
                                  accounts[i].id,
                                ),
                                accountCount: accounts.length,
                                isIncluded: !excludedAccountIds.contains(
                                  accounts[i].id,
                                ),
                                isOnline: isOnline,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  FadeSlideEntrance.staggered(
                    index: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Accounts you switch on are counted in your Safe to spend. Switch one off to keep it out, for example savings you do not want to touch.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: context.kColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  if (accounts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    FadeSlideEntrance.staggered(
                      index: 4,
                      child: PillButton(
                        label: 'Add account',
                        onPressed: isOnline
                            ? () => _showAddAccountSheet(context)
                            : null,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    WidgetRef ref, {
    required Account account,
    required String balanceLabel,
    required int accountCount,
    required bool isIncluded,
    required bool isOnline,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(color: context.kColors.cardBorderStrong, width: 1),
                ),
                child: Center(
                  child: Icon(
                    _iconForType(account.type),
                    color: context.kColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.kColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _descriptionForType(account.type),
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: context.kColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                balanceLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: context.kColors.textPrimary,
                  fontFeatures: CurrencyFormatter.tabularFigures,
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  color: context.kColors.textSecondary,
                  size: 20,
                ),
                color: context.kColors.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(color: context.kColors.cardBorder),
                ),
                onSelected: (action) {
                  if (action == 'reconcile') {
                    showReconcileBalanceSheet(context, targetAccount: account);
                  } else if (action == 'archive') {
                    _archiveAccount(context, ref, account, accountCount);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reconcile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: context.kColors.textPrimary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Reconcile balance',
                          style: GoogleFonts.dmSans(
                            color: context.kColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    enabled: isOnline,
                    child: Row(
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 18,
                          color: context.kColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isOnline
                              ? 'Archive account'
                              : 'Archive (needs internet)',
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 13),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: context.kColors.icon.withValues(alpha: 0.14), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Count in safe to spend',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: context.kColors.textSecondary,
                  ),
                ),
                FigmaToggleSwitch(
                  value: isIncluded,
                  onChanged: (_) => ref
                      .read(excludedAccountsProvider.notifier)
                      .toggle(account.id),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountsHeader extends StatelessWidget {
  const _AccountsHeader();

  @override
  Widget build(BuildContext context) {
    return FadeSlideEntrance.staggered(
      index: 0,
      child: Row(
        children: [
          SpringTouch(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/settings');
              }
            },
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: context.kColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.kColors.cardBorder, width: 1),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: context.kColors.textPrimary,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Accounts',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: context.kColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAccountSheet extends ConsumerStatefulWidget {
  const _AddAccountSheet();

  @override
  ConsumerState<_AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<_AddAccountSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0');
  String _accountType = 'cash';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!ref.read(isOnlineProvider)) {
      KasyabaToast.showInfo(
        context,
        'Adding accounts needs an internet connection.',
      );
      return;
    }

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text.trim());
    if (name.isEmpty || balance == null || balance < 0) {
      KasyabaToast.showError(
        context,
        'Enter an account name and a valid opening balance.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(transactionMutatorProvider)
          .createAccount(
            name: name,
            type: _accountType,
            openingBalance: balance,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Could not create account. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isOnline = ref.watch(isOnlineProvider);

    return AppSheet(
      color: context.kColors.canvas,
      padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add account',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: context.kColors.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _SheetField(
            label: 'Account name',
            child: TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: kMaxNameLength,
              buildCounter: (
                context, {
                required currentLength,
                required isFocused,
                maxLength,
              }) => null,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.kColors.textPrimary,
              ),
              decoration: _inputDecoration('e.g. BPI Savings, Maya'),
            ),
          ),
          const SizedBox(height: 12),
          _SheetField(
            label: 'Account type',
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _accountType,
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
                items: const [
                  DropdownMenuItem(
                    value: 'cash',
                    child: Text('Cash Wallet (Physical Cash)'),
                  ),
                  DropdownMenuItem(
                    value: 'bank',
                    child: Text('Bank Account (BPI, BDO, UnionBank)'),
                  ),
                  DropdownMenuItem(
                    value: 'ewallet',
                    child: Text('E-wallet (GCash, Maya, GrabPay)'),
                  ),
                  DropdownMenuItem(
                    value: 'other',
                    child: Text('Other (Investment, Credit, Vault)'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _accountType = value);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SheetField(
            label: 'Opening balance',
            child: TextField(
              controller: _balanceController,
              inputFormatters: [currencyAmountInputFormatter],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.kColors.textPrimary,
              ),
              decoration: _inputDecoration('0.00').copyWith(
                prefixText: '₱ ',
                prefixStyle: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.kColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!isOnline) ...[
            const NeedsInternetNotice(
              message: 'Creating an account needs an internet connection.',
            ),
            const SizedBox(height: 12),
          ],
          PillButton(
            label: 'Add account',
            onPressed: isOnline ? _submit : null,
            isLoading: _isSubmitting,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.dmSans(color: context.kColors.icon.withValues(alpha: 0.4)),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
    );
  }
}

class _SheetField extends StatelessWidget {
  final String label;
  final Widget child;

  const _SheetField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: context.kColors.inputFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.kColors.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.kColors.textSecondary,
            ),
          ),
          child,
        ],
      ),
    );
  }
}
