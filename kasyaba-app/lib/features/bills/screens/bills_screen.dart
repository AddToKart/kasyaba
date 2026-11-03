import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// ─────────────────────────────────────────────────────────────
///  Bills Screen
///  Figma 1:1 Carbon Copy:
///    - Node 42:6729 (Upcoming Week view)
///    - Node 106:595 (Paid Week view & empty state)
///    - Node 106:723 (Overdue Week view & empty state)
///    - Node 106:937 (Upcoming Month view)
///    - Node 106:1563 (Paid Month view)
///    - Node 106:1740 (Overdue Month view)
/// ─────────────────────────────────────────────────────────────
class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDay = _dateOnly(DateTime.now());
  bool _isMonthView = false;
  String _activeFilter = 'Upcoming'; // 'Upcoming', 'Paid', 'Overdue'

  static const List<String> _quickAddPresets = [
    'Electricity',
    'Internet',
    'Water',
    'Housing Rent',
    'Mobile Plan',
    'Gym',
  ];

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/transactions');
    }
  }

  void _pickMonth() async {
    AppHaptics.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDatePickerMode: DatePickerMode.year,
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DashboardTokens.periwinkleGray,
              onPrimary: DashboardTokens.ebony,
              surface: DashboardTokens.bigStone,
              onSurface: DashboardTokens.periwinkleGray,
            ),
          ),
          child: child,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        _currentMonth = DateTime(picked.year, picked.month, 1);
        _selectedDay = _dateOnly(picked);
      });
    }
  }

  List<DateTime> _getWeekDays(DateTime anchor) {
    final weekday = anchor.weekday % 7; // Sunday=0, Monday=1, ...
    final sunday = anchor.subtract(Duration(days: weekday));
    return List.generate(7, (i) => _dateOnly(sunday.add(Duration(days: i))));
  }

  void _showBillActionSheet(BillItem bill) {
    AppHaptics.selectionClick();
    final isPaid = bill.status.toLowerCase() == 'paid';
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    String? selectedAccount = accounts.isNotEmpty ? accounts.first.id : null;
    var isSubmitting = false;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DashboardTokens.bigStone,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DashboardTokens.poloBlue22,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bill.name,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: DashboardTokens.periwinkleGray,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('EEE, MMM d, yyyy').format(bill.dueDate)} · ${bill.status.toUpperCase()}',
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(bill.amount),
                          style: GoogleFonts.dmSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isPaid
                                ? DashboardTokens.bermuda
                                : DashboardTokens.periwinkleGray,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (!isPaid) ...[
                      if (accounts.isNotEmpty) ...[
                        Text(
                          'PAY FROM ACCOUNT',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: DashboardTokens.ebony.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedAccount,
                              dropdownColor: DashboardTokens.bigStone,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: DashboardTokens.periwinkleGray),
                              items: accounts.map((acc) {
                                return DropdownMenuItem(
                                  value: acc.id,
                                  child: Text(
                                    acc.name,
                                    style: GoogleFonts.dmSans(
                                      fontWeight: FontWeight.bold,
                                      color: DashboardTokens.periwinkleGray,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) => setSheetState(() => selectedAccount = val),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isSubmitting || selectedAccount == null
                            ? null
                            : () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  AppHaptics.mediumImpact();
                                  await ref.read(transactionMutatorProvider).markBillPaid(
                                    billId: bill.id,
                                    accountId: selectedAccount!,
                                  );
                                  if (!mounted) return;
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  KasyabaToast.showSuccess(
                                    context,
                                    '${bill.name} marked as paid!',
                                    subtitle: 'Deducted ${CurrencyFormatter.format(bill.amount)}',
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    setSheetState(() => isSubmitting = false);
                                    KasyabaToast.showError(
                                      context,
                                      friendlyErrorMessage(e, fallback: 'Failed to mark bill as paid.'),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: DashboardTokens.periwinkleGray,
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DashboardTokens.ebony,
                                  ),
                                )
                              : Text(
                                  'Mark as Paid',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: DashboardTokens.ebony,
                                  ),
                                ),
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isSubmitting
                            ? null
                            : () async {
                                setSheetState(() => isSubmitting = true);
                                try {
                                  AppHaptics.mediumImpact();
                                  await ref.read(transactionMutatorProvider).markBillUnpaid(bill.id);
                                  if (!mounted) return;
                                  if (sheetContext.mounted) {
                                    Navigator.of(sheetContext).pop();
                                  }
                                  KasyabaToast.showInfo(
                                    context,
                                    '${bill.name} marked as unpaid',
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    setSheetState(() => isSubmitting = false);
                                    KasyabaToast.showError(
                                      context,
                                      friendlyErrorMessage(e, fallback: 'Failed to update bill.'),
                                    );
                                  }
                                }
                              },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            border: Border.all(color: DashboardTokens.poloBlue30, width: 1),
                            borderRadius: BorderRadius.circular(26),
                          ),
                          alignment: Alignment.center,
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                )
                              : Text(
                                  'Mark as Unpaid',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final billsAsync = ref.watch(billsProvider);
    final allBills = billsAsync.valueOrNull ?? [];
    final today = _dateOnly(DateTime.now());

    // Filter bills into Upcoming, Paid, and Overdue
    final List<BillItem> displayedBills = allBills.where((b) {
      final bDate = _dateOnly(b.dueDate);
      final isPaid = b.status.toLowerCase() == 'paid';
      final isOverdue = !isPaid && bDate.isBefore(today);
      final isUpcoming = !isPaid && !isOverdue;

      if (_activeFilter == 'Upcoming') return isUpcoming;
      if (_activeFilter == 'Paid') return isPaid;
      if (_activeFilter == 'Overdue') return isOverdue;
      return true;
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Group bills by date for display
    final Map<String, List<BillItem>> groupedBills = {};
    for (final b in displayedBills) {
      final key = DateFormat('yyyy-MM-dd').format(b.dueDate);
      groupedBills.putIfAbsent(key, () => []).add(b);
    }
    final sortedGroupKeys = groupedBills.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    // Week days calculation
    final weekDays = _getWeekDays(_selectedDay);

    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
      child: Scaffold(
        backgroundColor: DashboardTokens.ebony,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: DashboardTokens.ebony,
            gradient: DashboardTokens.canvasGradient,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header Row (Back + Title + Plus Button) (Node 106:2510) ──
                Row(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.selectionClick();
                        _handleBack();
                      },
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
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: DashboardTokens.periwinkleGray,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bills',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.periwinkleGray,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.selectionClick();
                        context.push('/bills/add');
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: DashboardTokens.periwinkleGray,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.add_rounded,
                          color: DashboardTokens.ebony,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Month Selector & View Switcher Row (Node 11:1723) ────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickMonth,
                      child: Text(
                        DateFormat('MMMM yyyy').format(_currentMonth),
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.periwinkleGray,
                        ),
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() => _isMonthView = !_isMonthView);
                      },
                      child: Text(
                        _isMonthView ? 'Show week' : 'Show full month',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.periwinkleGraySubtitle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Calendar Component (Adaptive: Week Strip vs. Full Month) ─
                if (!_isMonthView) ...[
                  // 7-Day Week Calendar Strip (Node 11:1728)
                  Row(
                    children: weekDays.map((day) {
                      final dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                      final dayLetter = dayLetters[day.weekday % 7];
                      final isSelected = day.year == _selectedDay.year &&
                          day.month == _selectedDay.month &&
                          day.day == _selectedDay.day;
                      final hasBill = allBills.any((b) {
                        final bDate = _dateOnly(b.dueDate);
                        return bDate.year == day.year &&
                            bDate.month == day.month &&
                            bDate.day == day.day;
                      });

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            AppHaptics.selectionClick();
                            setState(() => _selectedDay = day);
                          },
                          child: Container(
                            height: 60,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DashboardTokens.periwinkleGray
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  dayLetter,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? DashboardTokens.ebony
                                        : DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${day.day}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? DashboardTokens.ebony
                                        : DashboardTokens.periwinkleGray,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (hasBill)
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? DashboardTokens.ebony
                                          : DashboardTokens.apricot,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  )
                                else
                                  const SizedBox(height: 4),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // Full Month Calendar View (Node 106:1278)
                  _buildMonthCalendar(allBills),
                ],
                const SizedBox(height: 16),

                // ── 3-Way Filter Pill: Upcoming / Paid / Overdue (Node 11:1764)
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildBillsFilterTab('Upcoming'),
                      _buildBillsFilterTab('Paid'),
                      _buildBillsFilterTab('Overdue'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Bills List or Empty State ────────────────────────────────
                if (billsAsync.isLoading && allBills.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DashboardTokens.periwinkleGray,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ] else if (displayedBills.isEmpty) ...[
                  // Exact Empty State matching Node 106:595 / 106:723
                  _buildEmptyStateCard(),
                ] else ...[
                  ...sortedGroupKeys.map((groupKey) {
                    final items = groupedBills[groupKey]!;
                    final groupDate = items.first.dueDate;
                    final groupTitle = DateFormat('EEE, MMM d').format(groupDate);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date Header (Node 11:1677)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            child: Text(
                              groupTitle,
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                          ),
                          // Bills in this group
                          ...items.map((bill) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildBillCard(bill, today),
                              )),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 14),

                // ── Quick Add Section (Node 11:1783) ─────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QUICK ADD',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 10,
                      children: _quickAddPresets.map((preset) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            AppHaptics.selectionClick();
                            context.push('/bills/add', extra: preset);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: DashboardTokens.poloBlue.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              preset,
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Month Calendar Card (Node 106:1278) ───────────────────────────────────
  Widget _buildMonthCalendar(List<BillItem> allBills) {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leadingBlanks = firstDayOfMonth.weekday % 7; // Sunday=0, Monday=1...

    final totalCells = leadingBlanks + daysInMonth;
    final totalRows = (totalCells / 7).ceil();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 15),
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
          // Day Initials Row (S, M, T, W, T, F, S)
          Row(
            children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((initial) {
              return Expanded(
                child: Center(
                  child: Text(
                    initial,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),

          // Days Grid
          for (int r = 0; r < totalRows; r++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: List.generate(7, (c) {
                  final dayIndex = r * 7 + c;
                  final dayNum = dayIndex - leadingBlanks + 1;

                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 44));
                  }

                  final cellDate = DateTime(year, month, dayNum);
                  final isSelected = cellDate.year == _selectedDay.year &&
                      cellDate.month == _selectedDay.month &&
                      cellDate.day == _selectedDay.day;

                  final hasBill = allBills.any((b) {
                    final bDate = _dateOnly(b.dueDate);
                    return bDate.year == year &&
                        bDate.month == month &&
                        bDate.day == dayNum;
                  });

                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() => _selectedDay = cellDate);
                      },
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? DashboardTokens.periwinkleGray
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNum',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? DashboardTokens.ebony
                                    : DashboardTokens.periwinkleGray,
                              ),
                            ),
                            if (hasBill)
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? DashboardTokens.ebony
                                      : DashboardTokens.apricot,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              )
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── 3-Way Bills Filter Tab ────────────────────────────────────────────────
  Widget _buildBillsFilterTab(String label) {
    final isSelected = _activeFilter == label;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selectionClick();
          setState(() => _activeFilter = label);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? DashboardTokens.periwinkleGray : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? DashboardTokens.ebony
                  : DashboardTokens.periwinkleGraySubtitle,
            ),
          ),
        ),
      ),
    );
  }

  // ── Bill Card (Node 11:1678) ──────────────────────────────────────────────
  Widget _buildBillCard(BillItem bill, DateTime today) {
    final bDate = _dateOnly(bill.dueDate);
    final daysUntil = bDate.difference(today).inDays;
    final isPaid = bill.status.toLowerCase() == 'paid';

    final String subtitle;
    final Color statusColor;

    if (isPaid) {
      subtitle = 'Paid · Monthly';
      statusColor = DashboardTokens.bermuda;
    } else if (daysUntil < 0) {
      subtitle = 'Monthly · overdue by ${-daysUntil} days';
      statusColor = DashboardTokens.apricot;
    } else if (daysUntil == 0) {
      subtitle = 'Monthly · due today';
      statusColor = DashboardTokens.apricot;
    } else {
      subtitle = 'Monthly · due in $daysUntil days';
      statusColor = DashboardTokens.periwinkleGraySubtitle;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showBillActionSheet(bill),
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: DashboardTokens.bigStone,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: DashboardTokens.poloBlue22,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.format(bill.amount),
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isPaid
                    ? DashboardTokens.bermuda
                    : DashboardTokens.periwinkleGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State Card (Node 106:691 / 106:819) ─────────────────────────────
  Widget _buildEmptyStateCard() {
    final emptyTitle = _activeFilter == 'Paid'
        ? 'No paid bills this period'
        : (_activeFilter == 'Overdue'
            ? 'No overdue bills this period'
            : 'No bills this week');

    final emptySubtitle = _activeFilter == 'Paid'
        ? 'Bills you mark as paid will show up here.'
        : (_activeFilter == 'Overdue'
            ? 'Great job! You have no overdue bills.'
            : 'Add a bill to get a reminder before it is due.');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 24),
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
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DashboardTokens.kashmirBlue,
                width: 1,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 26,
              color: DashboardTokens.periwinkleGray,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            emptyTitle,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTokens.periwinkleGray,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            emptySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: DashboardTokens.periwinkleGraySubtitle,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AppHaptics.selectionClick();
              context.push('/bills/add');
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: DashboardTokens.periwinkleGray,
                borderRadius: BorderRadius.circular(28),
              ),
              alignment: Alignment.center,
              child: Text(
                'Add a bill',
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: DashboardTokens.ebony,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
