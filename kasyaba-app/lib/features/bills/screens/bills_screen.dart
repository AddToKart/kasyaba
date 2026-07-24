import 'package:flutter/material.dart';

class BillsScreen extends StatelessWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Add bill template dialog
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tab-style filter
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'upcoming', label: Text('Upcoming')),
              ButtonSegment(value: 'paid', label: Text('Paid')),
              ButtonSegment(value: 'overdue', label: Text('Overdue')),
            ],
            selected: const {'upcoming'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 16),

          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.receipt_long, size: 48, color: theme.colorScheme.outline),
                  const SizedBox(height: 8),
                  Text(
                    'No bills to show',
                    style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add bill template
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
