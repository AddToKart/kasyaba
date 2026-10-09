import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/providers/api_providers.dart';

DateTime _transferDateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

class AddTransferScreen extends ConsumerStatefulWidget {
  const AddTransferScreen({super.key});

  @override
  ConsumerState<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends ConsumerState<AddTransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _fromAccount;
  String? _toAccount;
  DateTime _date = _transferDateOnly(DateTime.now());
  bool _isSaving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
    );
    if (selected != null && mounted) {
      setState(() => _date = _transferDateOnly(selected));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final from = _fromAccount;
    final to = _toAccount;
    if (from == null || to == null || from == to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose two different accounts.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final saveStatus = await ref.read(transactionMutatorProvider).addTransfer(
        fromAccountId: from,
        toAccountId: to,
        amount: double.parse(_amountController.text.trim()),
        transferredAt: _date,
        notes: _notesController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveStatus == TransactionSaveStatus.queued
                ? 'Transfer saved offline — will sync when online.'
                : 'Transfer recorded.',
          ),
        ),
      );
      context.pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save the transfer.')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.lightBg,
      appBar: AppBar(
        title: const Text('Transfer Money'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: accountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: FilledButton.tonal(
              onPressed: () => ref.invalidate(accountsProvider),
              child: const Text('Retry accounts'),
            ),
          ),
          data: (accounts) {
            if (accounts.length < 2) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Create at least two accounts before recording a transfer.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: () => context.push('/accounts'),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Manage accounts'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₱ ',
                      ),
                      validator: (value) {
                        final amount = double.tryParse(value?.trim() ?? '');
                        return amount == null || amount <= 0
                            ? 'Enter an amount greater than zero'
                            : null;
                      },
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _fromAccount,
                      decoration: const InputDecoration(labelText: 'From account'),
                      items: accounts
                          .map((account) => DropdownMenuItem(
                                value: account.id,
                                child: Text(account.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _fromAccount = value),
                      validator: (value) => value == null ? 'Choose an account' : null,
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      initialValue: _toAccount,
                      decoration: const InputDecoration(labelText: 'To account'),
                      items: accounts
                          .map((account) => DropdownMenuItem(
                                value: account.id,
                                child: Text(account.name),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _toAccount = value),
                      validator: (value) => value == null ? 'Choose an account' : null,
                    ),
                    const SizedBox(height: 18),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Transfer date'),
                      subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.swap_horiz_rounded),
                      label: Text(_isSaving ? 'Saving...' : 'Record Transfer'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
