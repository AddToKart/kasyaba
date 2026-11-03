import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/figma_toggle_switch.dart';
import '../../../shared/widgets/motion_components.dart';
import '../widgets/reconcile_balance_sheet.dart';

/// ─────────────────────────────────────────────────────────────
///  1:1 Figma Accounts and Wallets Screen (Node 42:6865)
/// ─────────────────────────────────────────────────────────────
class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  // Set of account IDs excluded from Safe to Spend calculation
  final Set<String> _excludedAccountIds = <String>{};

  void _showAddAccountSheet(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0');
    var accountType = 'cash';
    var isSubmitting = false;

    showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Modal Handle
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

                // Modal Title
                const Text(
                  'Add account',
                  style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: DashboardTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 18),

                // Account Name Input Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.periwinkleGray,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Account name',
                      labelStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                      hintText: 'e.g. BPI Savings, Maya',
                      hintStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        color: DashboardTokens.poloBlue40,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Account Type Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: accountType,
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
                      onChanged: (val) {
                        if (val != null) setSheetState(() => accountType = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Opening Balance Input Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.periwinkleGray,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Opening balance',
                      labelStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                      prefixText: '₱ ',
                      prefixStyle: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: DashboardTokens.periwinkleGray,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                SpringTouch(
                  onTap: isSubmitting
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          final balance = double.tryParse(balanceController.text.trim());
                          if (name.isEmpty || balance == null || balance < 0) return;

                          setSheetState(() => isSubmitting = true);
                          try {
                            await ref.read(transactionMutatorProvider).createAccount(
                                  name: name,
                                  type: accountType,
                                  openingBalance: balance,
                                );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop(true);
                            }
                          } catch (error) {
                            if (sheetContext.mounted) {
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    friendlyErrorMessage(
                                      error,
                                      fallback: 'Could not create account. Please try again.',
                                    ),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (sheetContext.mounted) {
                              setSheetState(() => isSubmitting = false);
                            }
                          }
                        },
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: DashboardTokens.periwinkleGray,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    alignment: Alignment.center,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(DashboardTokens.ebony),
                            ),
                          )
                        : const Text(
                            'Add account',
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
          );
        },
      ),
    );
  }

  Future<void> _archiveAccount(
    BuildContext context,
    Account account,
    int accountCount,
  ) async {
    if (accountCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keep at least one active account.')),
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: DashboardTokens.ebony,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: DashboardTokens.poloBlue22,
            width: 1,
          ),
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
              'Archive ${account.name}?',
              style: const TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'It will disappear from new transactions, but its history remains in your financial records.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: DashboardTokens.periwinkleGraySubtitle,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SpringTouch(
                    onTap: () => Navigator.of(sheetContext).pop(false),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: DashboardTokens.kashmirBlue,
                          width: 1,
                        ),
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
                    onTap: () => Navigator.of(sheetContext).pop(true),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: DashboardTokens.apricot,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Archive',
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

    if (!context.mounted || confirmed != true) return;

    try {
      await ref.read(transactionMutatorProvider).archiveAccount(account.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account archived.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyErrorMessage(
              error,
              fallback: 'Could not archive the account. Please try again.',
            ),
          ),
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

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final balancesAsync = ref.watch(accountBalancesProvider);
    final balances = balancesAsync.valueOrNull ?? const <String, double>{};

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
                child: accountsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(DashboardTokens.periwinkleGray),
                    ),
                  ),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: DashboardTokens.apricot,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              friendlyErrorMessage(
                                error,
                                fallback: 'Could not load your accounts.',
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                color: DashboardTokens.periwinkleGraySubtitle,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SpringTouch(
                              onTap: () => ref.invalidate(accountsProvider),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: DashboardTokens.periwinkleGray,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Try again',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
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
                  ),
                  data: (accounts) {
                    // Compute total across accounts
                    double totalBalance = 0.0;
                    for (final account in accounts) {
                      totalBalance += (balances[account.id] ?? 0.0);
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                      children: [
                        // Header row: 50x50 squircle back button + Title
                        FadeSlideEntrance.staggered(
                          index: 0,
                          child: Row(
                            children: [
                              SpringTouch(
                                onTap: () => context.pop(),
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
                              const Text(
                                'Accounts',
                                style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.periwinkleGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Total Balance Hero Card
                        FadeSlideEntrance.staggered(
                          index: 1,
                          child: Container(
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
                                const Text(
                                  'Total across accounts',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CurrencyFormatter.format(totalBalance),
                                  style: const TextStyle(
                                    fontFamily: 'Bricolage Grotesque',
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.periwinkleGray,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Accounts Group Card
                        if (accounts.isNotEmpty)
                          FadeSlideEntrance.staggered(
                            index: 2,
                            child: Container(
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
                                  for (int i = 0; i < accounts.length; i++) ...[
                                    if (i > 0)
                                      Container(
                                        height: 1,
                                        color: DashboardTokens.poloBlue16,
                                      ),
                                    _buildAccountItem(
                                      account: accounts[i],
                                      balance: balances[accounts[i].id] ?? 0.0,
                                      accountCount: accounts.length,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 12),

                        // Footnote
                        FadeSlideEntrance.staggered(
                          index: 3,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              'Accounts you switch on are counted in your Safe to spend. Switch one off to keep it out, for example savings you do not want to touch.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Add account button
                        FadeSlideEntrance.staggered(
                          index: 4,
                          child: SpringTouch(
                            onTap: () => _showAddAccountSheet(context),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color: DashboardTokens.periwinkleGray,
                                borderRadius: BorderRadius.circular(28),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'Add account',
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountItem({
    required Account account,
    required double balance,
    required int accountCount,
  }) {
    final isIncludedInSafeSpend = !_excludedAccountIds.contains(account.id);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          // Top row: Icon, Name + Type, Balance, More options
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: DashboardTokens.poloBlue30,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _iconForType(account.type),
                    color: DashboardTokens.periwinkleGray,
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
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _descriptionForType(account.type),
                      style: const TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                CurrencyFormatter.format(balance),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: DashboardTokens.periwinkleGray,
                ),
              ),
              const SizedBox(width: 4),
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
                onSelected: (action) {
                  if (action == 'reconcile') {
                    showReconcileBalanceSheet(context, targetAccount: account);
                  } else if (action == 'archive') {
                    _archiveAccount(context, account, accountCount);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reconcile',
                    child: Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: DashboardTokens.periwinkleGray,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Reconcile balance',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            color: DashboardTokens.periwinkleGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'archive',
                    child: Row(
                      children: [
                        Icon(
                          Icons.archive_outlined,
                          size: 18,
                          color: DashboardTokens.apricot,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Archive account',
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
          const SizedBox(height: 12),

          // Bottom toggle row: "Count in safe to spend"
          Container(
            padding: const EdgeInsets.only(top: 13),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: DashboardTokens.poloBlue14,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Count in safe to spend',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
                FigmaToggleSwitch(
                  value: isIncludedInSafeSpend,
                  onChanged: (val) {
                    setState(() {
                      if (val) {
                        _excludedAccountIds.remove(account.id);
                      } else {
                        _excludedAccountIds.add(account.id);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
