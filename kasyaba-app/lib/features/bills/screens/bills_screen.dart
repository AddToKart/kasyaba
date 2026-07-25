import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_text_field.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  String _selectedFilter = 'upcoming';

  void _showAddBillBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final presets = [
      {'name': 'Internet Bill', 'icon': '🌐'},
      {'name': 'Electric Bill', 'icon': '⚡'},
      {'name': 'Water Bill', 'icon': '💧'},
      {'name': 'Mobile Plan', 'icon': '📱'},
      {'name': 'Housing Rent', 'icon': '🏠'},
    ];

    ModernBottomSheet.show(
      context: context,
      title: 'Add Bill Reminder',
      subtitle: 'Schedule upcoming recurring bills to avoid late fees.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Presets',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: presets.map((preset) {
                return ActionChip(
                  avatar: Text(preset['icon']!),
                  label: Text(preset['name']!),
                  onPressed: () {
                    nameController.text = preset['name']!;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            ModernTextField(
              controller: nameController,
              label: 'Bill Name',
              hint: 'e.g. Internet Bill, Electric Bill',
              prefixIcon: Icons.receipt_long_outlined,
              validator: (v) => (v?.trim().length ?? 0) > 0 ? null : 'Bill name is required',
            ),
            const SizedBox(height: 16),

            ModernTextField(
              controller: amountController,
              label: 'Amount (₱)',
              hint: '1500.00',
              prefixIcon: Icons.account_balance_wallet_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter bill amount';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                final mutator = ref.read(transactionMutatorProvider);
                await mutator.addBill(
                  name: name,
                  amount: amount,
                  startsOn: DateTime.now().add(const Duration(days: 7)),
                );
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.check, size: 20),
              label: const Text('Save Bill Reminder', style: TextStyle(fontWeight: FontWeight.bold)),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Bills & Reminders',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Bill',
            onPressed: () => _showAddBillBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(billsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Segmented Filter
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'upcoming', label: Text('Upcoming')),
                ButtonSegment(value: 'paid', label: Text('Paid')),
                ButtonSegment(value: 'overdue', label: Text('Overdue')),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (v) => setState(() => _selectedFilter = v.first),
            ),
            const SizedBox(height: 20),

            billsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading bills: $err'),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return ModernCard(
                    padding: EdgeInsets.zero,
                    child: EmptyStateView(
                      title: 'No Bills Scheduled',
                      message: 'Never miss a due date. Track your Internet, Electricity, or Water bill reminders.',
                      icon: Icons.receipt_long_outlined,
                      actionLabel: 'Add Bill Reminder',
                      onAction: () => _showAddBillBottomSheet(context),
                    ),
                  );
                }

                return ModernCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < bills.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.receipt_long_outlined, color: Color(0xFFF59E0B), size: 20),
                          ),
                          title: Text(bills[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Due: ${bills[i].dueDate.toIso8601String().split("T")[0]}'),
                          trailing: Text(
                            '₱${bills[i].amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444), fontSize: 15),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillBottomSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Bill'),
      ),
    );
  }
}
