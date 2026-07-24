import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isExpense = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Type toggle
          Row(
            children: [
              Expanded(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Expense')),
                    ButtonSegment(value: false, label: Text('Income')),
                  ],
                  selected: {_isExpense},
                  onSelectionChanged: (v) => setState(() => _isExpense = v.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Amount
          TextFormField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₱ ',
              prefixStyle: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),

          // Description
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'What was this for?',
            ),
          ),
          const SizedBox(height: 16),

          // Category
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'food', child: Text('Food')),
              DropdownMenuItem(value: 'transport', child: Text('Transportation')),
              DropdownMenuItem(value: 'utilities', child: Text('Utilities')),
              DropdownMenuItem(value: 'rent', child: Text('Rent')),
              DropdownMenuItem(value: 'other', child: Text('Other')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),

          // Account
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Account',
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'bank', child: Text('Bank Account')),
            ],
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),

          // Date
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(Icons.calendar_today),
              suffixIcon: Icon(Icons.date_range),
            ),
            readOnly: true,
            onTap: () {
              showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
            },
          ),
          const SizedBox(height: 24),

          FilledButton.icon(
            onPressed: () {
              // TODO: Submit transaction
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction added')),
              );
              context.pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('Save Transaction'),
          ),
        ],
      ),
    );
  }
}
