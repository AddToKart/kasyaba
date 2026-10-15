import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../app/router/app_shell.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
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
      {'name': 'Internet Bill', 'icon': Icons.wifi_rounded},
      {'name': 'Electric Bill', 'icon': Icons.bolt_rounded},
      {'name': 'Water Bill', 'icon': Icons.water_drop_outlined},
      {'name': 'Mobile Plan', 'icon': Icons.smartphone_rounded},
      {'name': 'Housing Rent', 'icon': Icons.home_outlined},
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
                  avatar: Icon(
                    preset['icon'] as IconData,
                    size: 15,
                    color: AppColors.emerald500,
                  ),
                  label: Text(preset['name'] as String),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.tagRadius),
                    side: const BorderSide(color: AppColors.subtleBorder),
                  ),
                  onPressed: () {
                    _billNameController.text = preset['name'] as String;
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
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
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

  void _showBillActionsBottomSheet(BuildContext context, BillItem bill) {
    final isPaid = bill.status.toLowerCase() == 'paid';
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    String? selectedAccount = accounts.firstOrNull?.id;
    bool isSubmitting = false;

    ModernBottomSheet.show(
      context: context,
      title: bill.name,
      subtitle: 'Due date: ${DateFormat('MMMM d, yyyy').format(bill.dueDate)}',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface800,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.subtleBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AMOUNT DUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(bill.amount),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isPaid
                                ? AppColors.emerald500
                                : AppColors.gold500)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(
                          AppTheme.tagRadius,
                        ),
                        border: Border.all(
                          color: (isPaid
                                  ? AppColors.emerald500
                                  : AppColors.gold500)
                              .withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        bill.status.toUpperCase(),
                        style: TextStyle(
                          color: isPaid
                              ? AppColors.emerald500
                              : AppColors.gold500,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (!isPaid) ...[
                if (accounts.isNotEmpty) ...[
                  const Text(
                    'Pay from Account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: selectedAccount,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface800,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.subtleBorder),
                      ),
                    ),
                    items: accounts
                        .map(
                          (a) => DropdownMenuItem(
                            value: a.id,
                            child: Text(a.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setModalState(() => selectedAccount = val),
                  ),
                  const SizedBox(height: 16),
                ],

                FilledButton.icon(
                  onPressed: isSubmitting || selectedAccount == null
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await ref.read(transactionMutatorProvider).markBillPaid(
                              billId: bill.id,
                              accountId: selectedAccount!,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${bill.name} marked as paid!'),
                                  backgroundColor: AppColors.emerald500,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(friendlyErrorMessage(e, fallback: 'Failed to mark bill as paid.')),
                                  backgroundColor: AppColors.expense,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: Text(isSubmitting ? 'Processing...' : 'Mark as Paid'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald500,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setModalState(() => isSubmitting = true);
                          try {
                            await ref.read(transactionMutatorProvider).markBillUnpaid(bill.id);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${bill.name} marked as unpaid.'),
                                  backgroundColor: AppColors.gold500,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(friendlyErrorMessage(e, fallback: 'Failed to update bill.')),
                                  backgroundColor: AppColors.expense,
                                ),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.undo_rounded, size: 18),
                  label: Text(isSubmitting ? 'Processing...' : 'Mark as Unpaid'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold400,
                    side: const BorderSide(color: AppColors.gold500),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  bool _isBillOverdue(BillItem bill, DateTime today) {
    if (bill.status.toLowerCase() == 'paid') return false;
    if (bill.status.toLowerCase() == 'overdue') return true;
    final billDay = DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day);
    return billDay.isBefore(today);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, size: 14, color: AppColors.emerald500),
            const SizedBox(width: 6),
            Text(
              'Due on ${DateFormat('MMM d, yyyy').format(_selectedDay)}',
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
        (bill) {
          final isOverdue = _isBillOverdue(bill, today);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: ModernCard(
              padding: EdgeInsets.zero,
              borderRadius: 16,
              child: ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                onTap: () => _showBillActionsBottomSheet(context, bill),
                leading: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (isOverdue ? AppColors.expense : AppColors.gold500).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: isOverdue ? AppColors.expense : AppColors.gold500,
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
                  CurrencyFormatter.format(bill.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? AppColors.expense : (isDark ? AppColors.textDark : AppColors.textLight),
                    fontSize: 14,
                    fontFeatures: CurrencyFormatter.tabularFigures,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final billsAsync = ref.watch(billsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Bills & Reminders',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.emerald500,
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
                todayTextStyle: const TextStyle(
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
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                weekendTextStyle: TextStyle(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
                outsideTextStyle: TextStyle(
                  color: isDark
                      ? AppColors.textMuted.withValues(alpha: 0.35)
                      : AppColors.textMutedL.withValues(alpha: 0.35),
                ),
              ),
              headerStyle: HeaderStyle(
                titleTextStyle: TextStyle(
                  color: isDark ? AppColors.textDark : AppColors.textLight,
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
                  borderRadius: const BorderRadius.all(Radius.circular(12.0)),
                ),
                leftChevronIcon: const Icon(
                  Icons.chevron_left,
                  color: AppColors.emerald400,
                ),
                rightChevronIcon: const Icon(
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
              style: ButtonStyle(
                shape: WidgetStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
              ),
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
                child: Center(child: CircularProgressIndicator(color: AppColors.emerald500)),
              ),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 20,
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
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                        ),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (bills) {
                if (bills.isEmpty) {
                  return ModernCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 20,
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

                final filteredBills = bills.where((bill) {
                  if (_selectedFilter == 'paid') {
                    return bill.status.toLowerCase() == 'paid';
                  } else if (_selectedFilter == 'overdue') {
                    return _isBillOverdue(bill, today);
                  } else {
                    return bill.status.toLowerCase() != 'paid' && !_isBillOverdue(bill, today);
                  }
                }).toList();

                if (filteredBills.isEmpty) {
                  return ModernCard(
                    padding: const EdgeInsets.all(24),
                    borderRadius: 20,
                    child: Text(
                      'No $_selectedFilter bills right now.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }

                return ModernCard(
                  padding: EdgeInsets.zero,
                  borderRadius: 20,
                  child: Column(
                    children: [
                      for (int i = 0; i < filteredBills.length; i++) ...[
                        if (i > 0) const Divider(height: 1, indent: 56),
                        () {
                          final bill = filteredBills[i];
                          final isOverdue = _isBillOverdue(bill, today);
                          final daysOverdue = isOverdue
                              ? today.difference(DateTime(bill.dueDate.year, bill.dueDate.month, bill.dueDate.day)).inDays
                              : 0;

                          return ListTile(
                            onTap: () => _showBillActionsBottomSheet(context, bill),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isOverdue ? AppColors.expense : AppColors.gold500).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.receipt_long_outlined,
                                color: isOverdue ? AppColors.expense : AppColors.gold500,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              bill.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Row(
                              children: [
                                Text(
                                  'Due: ${DateFormat('MMM d, yyyy').format(bill.dueDate)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (isOverdue) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.expense.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(AppTheme.tagRadius),
                                      border: Border.all(
                                        color: AppColors.expense.withValues(alpha: 0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      daysOverdue > 0 ? '$daysOverdue${daysOverdue == 1 ? "d" : "d"} overdue' : 'Overdue',
                                      style: const TextStyle(
                                        color: AppColors.expense,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: Text(
                              CurrencyFormatter.format(bill.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOverdue
                                    ? AppColors.expense
                                    : (bill.status.toLowerCase() == 'paid'
                                        ? AppColors.emerald500
                                        : (isDark ? AppColors.textDark : AppColors.textLight)),
                                fontSize: 15,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                          );
                        }(),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 110),
          ],
        ),
      ),
      floatingActionButtonLocation: const FloatingDockFabLocation(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.emerald500,
          border: Border.all(
            color: AppColors.gold500.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddBillBottomSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, size: 22, color: Colors.black),
          label: const Text(
            'New Bill',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          tooltip: 'Add Bill',
        ),
      ),
    );
  }
}
