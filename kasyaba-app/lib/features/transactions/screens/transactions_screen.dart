import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/database/cache_service.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

Future<void> _showTransactionActions(
  BuildContext context,
  WidgetRef ref,
  TransactionEntry transaction,
) async {
  if (transaction.isSyncFailed) {
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: DashboardTokens.bigStone,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DashboardTokens.apricot.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.sync_problem_rounded,
                      color: DashboardTokens.apricot,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sync Failed',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                transaction.notes ?? 'This offline transaction could not be synced.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.refresh_rounded, color: DashboardTokens.bermuda),
                title: Text(
                  'Retry Sync',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.periwinkleGray,
                  ),
                ),
                subtitle: Text(
                  'Re-queue this transaction for the next sync',
                  style: GoogleFonts.dmSans(color: DashboardTokens.periwinkleGraySubtitle),
                ),
                onTap: () => Navigator.of(sheetContext).pop('retry'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.delete_outline_rounded, color: DashboardTokens.apricot),
                title: Text(
                  'Delete Queued Entry',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.apricot,
                  ),
                ),
                subtitle: Text(
                  'Discard this transaction from local storage',
                  style: GoogleFonts.dmSans(color: DashboardTokens.periwinkleGraySubtitle),
                ),
                onTap: () => Navigator.of(sheetContext).pop('delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (action == 'retry') {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.retryFailedTransaction(transaction.id);
      final userId = ref.read(authProvider).userId;
      if (userId != null) {
        final dio = ref.read(dioProvider);
        unawaited(cacheService.syncPendingTransactions(dio, userId).catchError((_) => 0));
      }
      ref.invalidate(paginatedTransactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(accountBalancesProvider);
      if (context.mounted) {
        KasyabaToast.showInfo(
          context,
          'Transaction re-queued for sync',
          icon: Icons.sync_rounded,
        );
      }
    } else if (action == 'delete') {
      final cacheService = ref.read(cacheServiceProvider);
      await cacheService.deleteOfflineTransaction(transaction.id);
      ref.invalidate(paginatedTransactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(accountBalancesProvider);
      if (context.mounted) {
        KasyabaToast.showInfo(
          context,
          'Offline transaction discarded',
          icon: Icons.delete_outline_rounded,
        );
      }
    }
    return;
  }

  if (transaction.isPendingSync) {
    KasyabaToast.showInfo(
      context,
      'Stored locally',
      subtitle: 'Will automatically sync once connected.',
      icon: Icons.cloud_queue_rounded,
    );
    return;
  }

  final action = await showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    backgroundColor: DashboardTokens.bigStone,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!transaction.isTransfer)
            ListTile(
              leading: const Icon(Icons.edit_rounded, color: DashboardTokens.periwinkleGray),
              title: Text(
                'Edit transaction',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: DashboardTokens.periwinkleGray,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: DashboardTokens.apricot),
            title: Text(
              transaction.isTransfer ? 'Delete transfer' : 'Delete transaction',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: DashboardTokens.apricot,
              ),
            ),
            onTap: () => Navigator.of(sheetContext).pop('delete'),
          ),
        ],
      ),
    ),
  );

  if (!context.mounted || action == null) return;
  if (action == 'edit') {
    context.push('/transactions/edit', extra: transaction);
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: DashboardTokens.bigStone,
      title: Text(
        transaction.isTransfer ? 'Delete transfer?' : 'Delete transaction?',
        style: GoogleFonts.bricolageGrotesque(
          color: DashboardTokens.periwinkleGray,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        transaction.isTransfer
            ? 'This will restore the money to the source account and remove it from the destination account.'
            : 'This will remove it from your balances and reports.',
        style: GoogleFonts.dmSans(color: DashboardTokens.periwinkleGraySubtitle),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(color: DashboardTokens.periwinkleGraySubtitle),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: DashboardTokens.apricot),
          child: Text(
            'Delete',
            style: GoogleFonts.dmSans(color: DashboardTokens.ebony, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    ),
  );
  if (!context.mounted || confirmed != true) return;

  try {
    await ref.read(transactionMutatorProvider).deleteTransaction(transaction);
    if (!context.mounted) return;
    KasyabaToast.showSuccess(context, 'Transaction deleted.');
  } catch (_) {
    if (!context.mounted) return;
    KasyabaToast.showError(context, 'Could not delete the transaction.');
  }
}

/// ─────────────────────────────────────────────────────────────
///  Bills & Activity Screen (Figma Node 106:592)
/// ─────────────────────────────────────────────────────────────
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _activeFilter = 'All'; // 'All', 'Expenses', 'Income'
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedCalendarDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
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
            colorScheme: ColorScheme.dark(
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
      });
    }
  }

  // Calculate 7-day week days for calendar strip
  List<DateTime> _getWeekDays(DateTime anchor) {
    // Week starting Sunday
    final weekday = anchor.weekday % 7; // Sunday=0, Monday=1, ...
    final sunday = anchor.subtract(Duration(days: weekday));
    return List.generate(7, (i) => sunday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final paginatedAsync = ref.watch(paginatedTransactionsProvider);
    final billsAsync = ref.watch(billsProvider);

    final transactions = paginatedAsync.valueOrNull?.items ?? [];
    final bills = billsAsync.valueOrNull ?? [];

    // Filter transactions by search and active filter tab
    final query = _searchController.text.trim().toLowerCase();
    final filtered = transactions.where((t) {
      // Type filter
      if (_activeFilter == 'Expenses' && !t.isExpense) return false;
      if (_activeFilter == 'Income' && t.isExpense) return false;
      // Search query
      if (query.isNotEmpty) {
        final title = t.title.toLowerCase();
        final cat = t.categoryName.toLowerCase();
        final notes = (t.notes ?? '').toLowerCase();
        if (!title.contains(query) && !cat.contains(query) && !notes.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Calculate monthly totals from transactions in current month
    double monthlyIncome = 0.0;
    double monthlySpent = 0.0;
    for (final t in transactions) {
      if (t.date.year == _currentMonth.year && t.date.month == _currentMonth.month) {
        if (t.isExpense) {
          monthlySpent += t.amount;
        } else if (!t.isTransfer) {
          monthlyIncome += t.amount;
        }
      }
    }
    final netMonthly = monthlyIncome - monthlySpent;

    // Group transactions by date
    final Map<String, List<TransactionEntry>> groupedTransactions = {};
    for (final t in filtered) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      groupedTransactions.putIfAbsent(key, () => []).add(t);
    }
    final sortedGroupKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    // Current week calendar strip
    final weekDays = _getWeekDays(_selectedCalendarDay);
    final weekStartStr = DateFormat('MMM d').format(weekDays.first);
    final weekEndStr = DateFormat('d').format(weekDays.last);
    final weekRangeLabel = '$weekStartStr–$weekEndStr';

    // Upcoming bills logic
    final upcomingBills = bills.where((b) {
      return b.status.toLowerCase() != 'paid';
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

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
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header Row (Node 82:510) ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bills & Activity',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        AppHaptics.selectionClick();
                        setState(() {
                          _isSearchOpen = !_isSearchOpen;
                          if (!_isSearchOpen) _searchController.clear();
                        });
                      },
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.asset(
                          'assets/images/activity_search.svg',
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            DashboardTokens.periwinkleGray,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Inline Search Bar when toggled
                if (_isSearchOpen) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: DashboardTokens.bigStone,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: DashboardTokens.poloBlue30,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.search_rounded,
                          color: DashboardTokens.periwinkleGraySubtitle,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            autofocus: true,
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: DashboardTokens.periwinkleGray,
                            ),
                            cursorColor: DashboardTokens.periwinkleGray,
                            decoration: InputDecoration(
                              hintText: 'Search transactions...',
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 15,
                                color: DashboardTokens.periwinkleGraySubtitle.withValues(alpha: 0.5),
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              fillColor: Colors.transparent,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () => _searchController.clear(),
                            child: const Icon(
                              Icons.close_rounded,
                              color: DashboardTokens.periwinkleGraySubtitle,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // ── Month Selector & Net Row (Node 82:516) ──────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _pickMonth,
                      child: Row(
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_currentMonth),
                            style: GoogleFonts.dmSans(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SvgPicture.asset(
                            'assets/images/activity_chevron_down.svg',
                            width: 14,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                              DashboardTokens.periwinkleGraySubtitle,
                              BlendMode.srcIn,
                            ),
                          ),
                        ],
                      ),
                    ),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: DashboardTokens.periwinkleGraySubtitle,
                        ),
                        children: [
                          const TextSpan(text: 'Net '),
                          TextSpan(
                            text: CurrencyFormatter.format(netMonthly),
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Monthly Totals Row (Node 82:521) ─────────────────────────
                Row(
                  children: [
                    // Income Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Income',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: DashboardTokens.periwinkleGraySubtitle,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(monthlyIncome),
                              style: GoogleFonts.dmSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.bermuda,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Spent Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spent',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: DashboardTokens.periwinkleGraySubtitle,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(monthlySpent),
                              style: GoogleFonts.dmSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.apricot,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Upcoming Bills Section (Node 82:528) ────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upcoming bills',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/bills'),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/activity_add.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                DashboardTokens.periwinkleGray,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Add a bill',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Bill Schedule Card (Node 82:535)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Calendar Heading Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            weekRangeLabel,
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/bills'),
                            child: Text(
                              'View month',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // 7-Day Week Calendar Strip (Node 82:539)
                      Row(
                        children: weekDays.map((day) {
                          final dayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                          final dayLetter = dayLetters[day.weekday % 7];
                          final isSelected = day.year == _selectedCalendarDay.year &&
                              day.month == _selectedCalendarDay.month &&
                              day.day == _selectedCalendarDay.day;
                          final hasBill = bills.any((b) =>
                              b.dueDate.year == day.year &&
                              b.dueDate.month == day.month &&
                              b.dueDate.day == day.day);

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                AppHaptics.selectionClick();
                                setState(() => _selectedCalendarDay = day);
                              },
                              child: Container(
                                height: 57,
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
                                      dayLetter,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
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
                                    // Apricot dot if bill on this day
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
                      const SizedBox(height: 12),

                      // Hairline Divider
                      Container(
                        height: 1,
                        color: DashboardTokens.poloBlue16,
                      ),
                      const SizedBox(height: 12),

                      // Upcoming Bill Item (Node 82:574)
                      if (upcomingBills.isNotEmpty) ...[
                        _buildBillItemRow(upcomingBills.first),
                      ] else ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No upcoming bills this week',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Activity Section (Node 82:583) ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activity',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => context.push('/transactions/add'),
                      child: Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: DashboardTokens.periwinkleGray,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/activity_add.svg',
                              width: 18,
                              height: 18,
                              colorFilter: const ColorFilter.mode(
                                DashboardTokens.ebony,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Add transaction',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.ebony,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3-Way Filter Pill: All / Expenses / Income (Node 82:588)
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(4),
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
                      _buildActivityFilterTab('All'),
                      _buildActivityFilterTab('Expenses'),
                      _buildActivityFilterTab('Income'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grouped Daily Transactions List (Node 82:597) ───────────
                if (paginatedAsync.isLoading && transactions.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: DashboardTokens.periwinkleGray,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                ] else if (sortedGroupKeys.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        _isSearchOpen && _searchController.text.isNotEmpty
                            ? 'No transactions found matching "${_searchController.text}"'
                            : 'No transactions recorded yet',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: DashboardTokens.periwinkleGraySubtitle,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ] else ...[
                  ...sortedGroupKeys.map((groupKey) {
                    final groupItems = groupedTransactions[groupKey]!;
                    final firstDate = groupItems.first.date;
                    final groupHeaderDate = _formatGroupHeaderDate(firstDate);

                    // Daily net sum
                    double dailyNet = 0.0;
                    for (final item in groupItems) {
                      if (item.isExpense) {
                        dailyNet -= item.amount;
                      } else if (!item.isTransfer) {
                        dailyNet += item.amount;
                      }
                    }

                    final isNetPositive = dailyNet > 0;
                    final isNetNegative = dailyNet < 0;
                    final netSign = isNetPositive ? '+' : (isNetNegative ? '−' : '');
                    final netFormatted = '$netSign${CurrencyFormatter.format(dailyNet.abs())}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Date & daily net row (Node 82:598)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 4,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  groupHeaderDate,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                                Text(
                                  netFormatted,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isNetPositive
                                        ? DashboardTokens.bermuda
                                        : (isNetNegative
                                            ? DashboardTokens.periwinkleGraySubtitle
                                            : DashboardTokens.periwinkleGraySubtitle),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Transactions Card Container (Node 82:601)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: DashboardTokens.bigStone,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: DashboardTokens.poloBlue22,
                                width: 1,
                              ),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              itemCount: groupItems.length,
                              separatorBuilder: (_, _) => Container(
                                height: 1,
                                color: DashboardTokens.poloBlue16,
                              ),
                              itemBuilder: (ctx, idx) {
                                final t = groupItems[idx];
                                return _buildTransactionItemRow(t);
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Activity Filter Tab ───────────────────────────────────────────────────
  Widget _buildActivityFilterTab(String label) {
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
              fontSize: 13,
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

  // ── Bill Item Row (Node 82:574) ───────────────────────────────────────────
  Widget _buildBillItemRow(BillItem bill) {
    final dueFormatted = DateFormat('EEE, MMM d').format(bill.dueDate);
    final daysUntil = bill.dueDate.difference(DateTime.now()).inDays;
    final statusText = daysUntil < 0
        ? 'Overdue by ${-daysUntil} days'
        : (daysUntil == 0 ? 'Due today' : 'Due in $daysUntil days');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/bills'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
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
                  const SizedBox(height: 2),
                  Text(
                    '$dueFormatted · Monthly',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(bill.amount),
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.apricot,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Transaction Item Row (Node 82:603) ────────────────────────────────────
  Widget _buildTransactionItemRow(TransactionEntry t) {
    final isExpense = t.isExpense;
    final isTransfer = t.isTransfer;
    final amountSign = isExpense ? '−' : (isTransfer ? '' : '+');
    final amountColor = isExpense
        ? DashboardTokens.apricot
        : (isTransfer ? DashboardTokens.periwinkleGray : DashboardTokens.bermuda);

    return InkWell(
      onTap: () => _showTransactionActions(context, ref, t),
      onLongPress: () => _showTransactionActions(context, ref, t),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            // Squircle Category Icon (Node 82:604)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: DashboardTokens.ebony.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(
                  color: DashboardTokens.poloBlue30,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                CategoryIconHelper.getIcon(t.categoryName),
                size: 20,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Category details (Node 82:608)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount (Node 82:611)
            Text(
              '$amountSign${CurrencyFormatter.format(t.amount)}',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGroupHeaderDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final formatted = DateFormat('MMM d').format(date).toUpperCase();
    return isToday ? 'TODAY · $formatted' : formatted;
  }
}
