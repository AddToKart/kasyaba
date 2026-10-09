import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_messages.dart';
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
  final _billNameController = TextEditingController();
  final _billAmountController = TextEditingController();

  String _selectedFilter = 'upcoming';
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  @override
  void dispose() {
    _billNameController.dispose();
    _billAmountController.dispose();
    super.dispose();
  }

  void _showAddBillBottomSheet(BuildContext context) {
    _billNameController.clear();
    _billAmountController.clear();
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

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
                    _billNameController.text = preset['name']!;
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            ModernTextField(
              controller: _billNameController,
              label: 'Bill Name',
              hint: 'e.g. Internet Bill, Electric Bill',
              prefixIcon: Icons.receipt_long_outlined,
              validator: (v) =>
                  (v?.trim().length ?? 0) > 0 ? null : 'Bill name is required',
            ),
            const SizedBox(height: 16),

            ModernTextField(
              controller: _billAmountController,
              label: 'Amount (₱)',
              hint: '1500.00',
              prefixIcon: Icons.account_balance_wallet_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter bill amount';
                final amount = double.tryParse(v);
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter an amount greater than zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            StatefulBuilder(
              builder: (context, setModalState) {
                return FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSubmitting = true);
                          final name = _billNameController.text.trim();
                          final amount =
                              double.tryParse(
                                _billAmountController.text.trim(),
                              ) ??
                              0.0;
                          final mutator = ref.read(transactionMutatorProvider);
                          final startsOn = DateTime.now().add(
                            const Duration(days: 7),
                          );
                          try {
                            await mutator.addBill(
                              name: name,
                              amount: amount,
                              startsOn: startsOn,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    friendlyErrorMessage(
                                      error,
                                      fallback:
                                          'Unable to save this bill. Please try again.',
                                    ),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 20),
                  label: Text(
                    isSubmitting ? 'Saving Bill...' : 'Save Bill Reminder',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectedDayBills(AsyncValue<List<BillItem>> billsAsync) {
    final bills = billsAsync.valueOrNull;
    if (bills == null || bills.isEmpty) return [];

    final dueBills = bills
        .where(
          (b) =>
              b.dueDate.year == _selectedDay.year &&
              b.dueDate.month == _selectedDay.month &&
              b.dueDate.day == _selectedDay.day,
        )
        .toList();

    if (dueBills.isEmpty) return [];

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.event, size: 14, color: AppColors.emerald500),
            const SizedBox(width: 6),
            Text(
              'Due on ${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textMuted : AppColors.textMutedL,
              ),
            ),
          ],
        ),
      ),
      ...dueBills.map(
        (bill) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: ModernCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.expense.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.expense,
                  size: 16,
                ),
              ),
              title: Text(
                bill.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
              subtitle: Text(
                bill.status,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                ),
              ),
              trailing: Text(
                '₱${bill.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.expense,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
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
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
            // ── Calendar ───────────────────────────────────────
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 365)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              locale: 'en_US',
              onFormatChanged: (format) {
                if (mounted) setState(() => _calendarFormat = format);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onPageChanged: (focusedDay) {
                if (mounted) setState(() => _focusedDay = focusedDay);
              },
              eventLoader: (day) {
                final bills = billsAsync.valueOrNull ?? [];
                return bills
                    .where(
                      (b) =>
                          b.dueDate.year == day.year &&
                          b.dueDate.month == day.month &&
                          b.dueDate.day == day.day,
                    )
                    .toList();
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return const SizedBox.shrink();
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 2),
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppColors.emerald500,
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.emerald500.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: AppColors.emerald400,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: const BoxDecoration(
                  color: AppColors.emerald500,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                ),
                weekendTextStyle: TextStyle(
                  color: AppColors.expense.withValues(alpha: 0.7),
                ),
                outsideTextStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textMuted.withValues(alpha: 0.35)
                      : AppColors.textMutedL.withValues(alpha: 0.35),
                ),
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textDark
                      : AppColors.textLight,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
                formatButtonVisible: true,
                formatButtonTextStyle: const TextStyle(
                  color: AppColors.emerald500,
                  fontSize: 14,
                ),
                formatButtonDecoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12.0)),
                ),
                leftChevronIcon: Icon(
                  Icons.chevron_left,
                  color: AppColors.emerald400,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: AppColors.emerald400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // ── Bills Due This Day ──────────────────────────────
            ..._buildSelectedDayBills(billsAsync),
            const SizedBox(height: 16),
            // Segmented Filter
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'upcoming', label: Text('Upcoming')),
                ButtonSegment(value: 'paid', label: Text('Paid')),
                ButtonSegment(value: 'overdue', label: Text('Overdue')),
              ],
              selected: {_selectedFilter},
              onSelectionChanged: (v) =>
                  setState(() => _selectedFilter = v.first),
            ),
            const SizedBox(height: 20),

            billsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => ModernCard(
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
                        err,
                        fallback: 'Could not load your bills.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(billsProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return ModernCard(
                    padding: EdgeInsets.zero,
                    child: EmptyStateView(
                      title: 'No Bills Scheduled',
                      message:
                          'Never miss a due date. Track your Internet, Electricity, or Water bill reminders.',
                      icon: Icons.receipt_long_outlined,
                      actionLabel: 'Add Bill Reminder',
                      onAction: () => _showAddBillBottomSheet(context),
                    ),
                  );
                }

                final filteredBills = bills
                    .where(
                      (bill) =>
                          bill.status.toLowerCase() == _selectedFilter,
                    )
                    .toList();

                if (filteredBills.isEmpty) {
                  return ModernCard(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No $_selectedFilter bills right now.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  );
                }

                return ModernCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (int i = 0; i < filteredBills.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              color: Color(0xFFF59E0B),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            filteredBills[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Due: ${filteredBills[i].dueDate.toIso8601String().split("T")[0]}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '₱${filteredBills[i].amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                              fontSize: 15,
                            ),
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
