import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/modern_card.dart';

class AccountsScreen extends ConsumerStatefulWidget {
  const AccountsScreen({super.key});

  @override
  ConsumerState<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends ConsumerState<AccountsScreen> {
  final _nameController = TextEditingController();
  final _openingBalanceController = TextEditingController(text: '0');

  @override
  void dispose() {
    _nameController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  Future<void> _showAddAccount(BuildContext context) async {
    _nameController.clear();
    _openingBalanceController.text = '0';
    var type = 'cash';
    var isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Account name'),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank', child: Text('Bank')),
                    DropdownMenuItem(value: 'ewallet', child: Text('E-wallet')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => type = value);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _openingBalanceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Opening balance',
                    prefixText: '₱ ',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting
                  ? null
                  : () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final name = _nameController.text.trim();
                      final balance = double.tryParse(
                        _openingBalanceController.text.trim(),
                      );
                      if (name.isEmpty || balance == null || balance < 0) {
                        return;
                      }
                      setState(() => isSubmitting = true);
                      try {
                        await ref
                            .read(transactionMutatorProvider)
                            .createAccount(
                              name: name,
                              type: type,
                              openingBalance: balance,
                            );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext).pop(true);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                friendlyErrorMessage(
                                  error,
                                  fallback:
                                      'Could not create the account. Please try again.',
                                ),
                              ),
                            ),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add'),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account added.')),
      );
    }
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Archive ${account.name}?'),
        content: const Text(
          'It will disappear from new entries, but its history remains in your net worth.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Archive'),
          ),
        ],
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
    return switch (type) {
      'bank' => Icons.account_balance_rounded,
      'ewallet' => Icons.phone_android_rounded,
      'other' => Icons.wallet_rounded,
      _ => Icons.payments_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts & Wallets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccount(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add account'),
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.expense,
                    size: 30,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    friendlyErrorMessage(
                      error,
                      fallback: 'Could not load your accounts.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(accountsProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (accounts) {
          if (accounts.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                ModernCard(
                  child: EmptyStateView(
                    title: 'No active accounts',
                    message: 'Add a wallet, bank account, or e-wallet to start tracking.',
                    icon: Icons.account_balance_wallet_outlined,
                    actionLabel: 'Add account',
                    onAction: () => _showAddAccount(context),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final account = accounts[index];
              return ModernCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.emerald500.withValues(alpha: 0.16),
                    child: Icon(_iconForType(account.type), color: AppColors.emerald400),
                  ),
                  title: Text(account.name),
                  subtitle: Text(account.type.toUpperCase()),
                  trailing: IconButton(
                    tooltip: 'Archive account',
                    onPressed: () =>
                        _archiveAccount(context, account, accounts.length),
                    icon: const Icon(Icons.archive_outlined),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
