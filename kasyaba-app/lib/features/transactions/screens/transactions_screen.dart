import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/cache_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_date_picker.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

String? _billRecurrenceLabel(String? recurrence) {
  switch (recurrence?.toLowerCase()) {
    case 'monthly':
      return 'Monthly';
    case 'weekly':
      return 'Weekly';
    case 'once':
    case 'one-time':
    case 'one_time':
    case 'onetime':
    case 'none':
      return 'One-time';
    default:
      return null;
  }
}

Future<void> _showTransactionActions(
  BuildContext context,
  WidgetRef ref,
  TransactionEntry transaction,
) async {
  final colors = context.kColors;
  if (transaction.isSyncFailed) {
    final action = await showKasyabaSheet<String>(
      context: context,
      builder: (sheetContext) => AppSheet(
        color: colors.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.dangerTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sync_problem_rounded,
                      color: colors.danger,
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
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                transaction.notes ??
                    'This offline transaction could not be synced.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.refresh_rounded,
                  color: colors.success,
                ),
                title: Text(
                  'Retry Sync',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Re-queue this transaction for the next sync',
                  style: GoogleFonts.dmSans(
                    color: colors.textSecondary,
                  ),
                ),
                onTap: () => Navigator.of(sheetContext).pop('retry'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.danger,
                ),
                title: Text(
                  'Delete Queued Entry',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: colors.danger,
                  ),
                ),
                subtitle: Text(
                  'Discard this transaction from local storage',
                  style: GoogleFonts.dmSans(
                    color: colors.textSecondary,
                  ),
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
        unawaited(
          cacheService
              .syncPendingTransactions(dio, userId)
              .catchError((_) => 0),
        );
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

  if (!ref.read(isOnlineProvider)) {
    await showKasyabaSheet<void>(
      context: context,
      builder: (sheetContext) => AppSheet(
        color: colors.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                transaction.isTransfer
                    ? 'Transfer options'
                    : 'Transaction options',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const NeedsInternetNotice(
                message:
                    'Editing or deleting transactions needs an internet connection.',
              ),
              const SizedBox(height: 8),
              if (!transaction.isTransfer)
                ListTile(
                  enabled: false,
                  leading: Icon(
                    Icons.edit_rounded,
                    color: colors.textSecondary,
                  ),
                  title: Text(
                    'Edit transaction',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ListTile(
                enabled: false,
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: colors.textSecondary,
                ),
                title: Text(
                  transaction.isTransfer
                      ? 'Delete transfer'
                      : 'Delete transaction',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return;
  }

  final action = await showKasyabaSheet<String>(
    context: context,
    builder: (sheetContext) => AppSheet(
      color: colors.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!transaction.isTransfer)
            ListTile(
              leading: Icon(
                Icons.edit_rounded,
                color: colors.textPrimary,
              ),
              title: Text(
                'Edit transaction',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
          ListTile(
            leading: Icon(
              Icons.delete_outline_rounded,
              color: colors.danger,
            ),
            title: Text(
              transaction.isTransfer ? 'Delete transfer' : 'Delete transaction',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                color: colors.danger,
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
      backgroundColor: colors.card,
      title: Text(
        transaction.isTransfer ? 'Delete transfer?' : 'Delete transaction?',
        style: GoogleFonts.bricolageGrotesque(
          color: colors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        transaction.isTransfer
            ? 'This will restore the money to the source account and remove it from the destination account.'
            : 'This will remove it from your balances and reports.',
        style: GoogleFonts.dmSans(
          color: colors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Cancel',
            style: GoogleFonts.dmSans(
              color: colors.textSecondary,
            ),
          ),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colors.danger,
          ),
          child: Text(
            'Delete',
            style: GoogleFonts.dmSans(
              color: colors.onPrimaryButton,
              fontWeight: FontWeight.bold,
            ),
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
  } catch (e) {
    if (!context.mounted) return;
    KasyabaToast.showError(
      context,
      friendlyErrorMessage(e, fallback: 'Could not delete the transaction.'),
    );
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
  DateTime _currentMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime _selectedCalendarDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    final filterFrom = ref.read(transactionFilterProvider).fromDate;
    if (filterFrom != null) {
      _currentMonth = DateTime(filterFrom.year, filterFrom.month, 1);
    }
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
        return Theme(data: kasyabaDatePickerTheme(ctx), child: child);
      },
    );
    if (picked != null && mounted) {
      final month = DateTime(picked.year, picked.month, 1);
      setState(() {
        _currentMonth = month;
      });
      final filter = ref.read(transactionFilterProvider);
      ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
        page: 1,
        fromDate: month,
        toDate: DateTime(picked.year, picked.month + 1, 0, 23, 59, 59),
      );
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
    final colors = context.kColors;
    final topPadding = MediaQuery.paddingOf(context).top;
    final paginatedAsync = ref.watch(paginatedTransactionsProvider);
    final billsAsync = ref.watch(billsProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final activeFilter = ref.watch(transactionFilterProvider);

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
        if (!title.contains(query) &&
            !cat.contains(query) &&
            !notes.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();

    // Totals are computed from the loaded page (50/page) and exclude planned
    // or future-dated entries, matching the server's isPosted discipline.
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    double monthlyIncome = 0.0;
    double monthlySpent = 0.0;
    for (final t in transactions) {
      if (t.date.year == _currentMonth.year &&
          t.date.month == _currentMonth.month) {
        final entryDay = DateTime(t.date.year, t.date.month, t.date.day);
        final isPosted = t.status != 'planned' && !entryDay.isAfter(todayStart);
        if (!isPosted) continue;
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
    }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Only surface bills that actually fall inside the displayed week so the
    // "No upcoming bills this week" copy stays truthful.
    final weekEndExclusive = weekDays.last.add(const Duration(days: 1));
    final weekBills = upcomingBills.where((b) {
      final db = b.dueDate;
      final due = DateTime(db.year, db.month, db.day);
      return !due.isBefore(weekDays.first) && due.isBefore(weekEndExclusive);
    }).toList();

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
        backgroundColor: colors.canvas,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: colors.canvas,
            gradient: colors.backgroundGradient,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, topPadding + 12, 20, DashboardTokens.dockClearance),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Top Header Row (Node 82:510) ───────────────────────────
                FadeSlideEntrance.staggered(
                  index: 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bills & Activity',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
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
                                color: colors.card,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: colors.cardBorder,
                                  width: 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  colors.icon,
                                  BlendMode.srcIn,
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/activity_search.svg',
                                  width: 22,
                                  height: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_isSearchOpen) ...[
                        const SizedBox(height: 12),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colors.cardBorderStrong,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                color: colors.textSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _searchController,
                                  autofocus: true,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    color: colors.textPrimary,
                                  ),
                                  cursorColor: colors.textPrimary,
                                  decoration: InputDecoration(
                                    hintText: 'Search transactions...',
                                    hintStyle: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      color: colors.textSecondary
                                          .withValues(alpha: 0.5),
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
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: colors.textSecondary,
                                    size: 18,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                if (!isOnline) ...[
                  OfflineStatusBadge(
                    snapshotKey: CacheService.transactionsKey(
                      page: activeFilter.page,
                      from: activeFilter.fromDate,
                      to: activeFilter.toDate,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Month Selector & Net Row (Node 82:516) ──────────────────
                FadeSlideEntrance.staggered(
                  index: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                                    color: colors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    colors.icon,
                                    BlendMode.srcIn,
                                  ),
                                  child: SvgPicture.asset(
                                    'assets/images/activity_chevron_down.svg',
                                    width: 14,
                                    height: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: colors.textSecondary,
                              ),
                              children: [
                                const TextSpan(text: 'Net '),
                                TextSpan(
                                  text: CurrencyFormatter.format(netMonthly),
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.bold,
                                    color: colors.textPrimary,
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
                                color: colors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.cardBorder,
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
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(monthlyIncome),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: colors.success,
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
                                color: colors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: colors.cardBorder,
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
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(monthlySpent),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: colors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Upcoming Bills Section (Node 82:528) ────────────────────
                FadeSlideEntrance.staggered(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upcoming bills',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              SpringTouch(
                                scaleDown: 0.94,
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  context.push('/bills');
                                },
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: colors.cardBorder,
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'View bills',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SpringTouch(
                                scaleDown: 0.94,
                                onTap: () {
                                  AppHaptics.selectionClick();
                                  context.push('/bills/add');
                                },
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.textPrimary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      ColorFiltered(
                                        colorFilter: ColorFilter.mode(
                                          colors.onPrimaryButton,
                                          BlendMode.srcIn,
                                        ),
                                        child: SvgPicture.asset(
                                          'assets/images/activity_add.svg',
                                          width: 18,
                                          height: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add a bill',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: colors.onPrimaryButton,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Bill Schedule Card (Node 82:535)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.card,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colors.cardBorder,
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
                                    color:
                                        colors.textSecondary,
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
                                      color: colors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // 7-Day Week Calendar Strip (Node 82:539)
                            Row(
                              children: weekDays.map((day) {
                                final dayLetters = [
                                  'S',
                                  'M',
                                  'T',
                                  'W',
                                  'T',
                                  'F',
                                  'S',
                                ];
                                final dayLetter = dayLetters[day.weekday % 7];
                                final isSelected =
                                    day.year == _selectedCalendarDay.year &&
                                    day.month == _selectedCalendarDay.month &&
                                    day.day == _selectedCalendarDay.day;
                                final hasBill = bills.any(
                                  (b) =>
                                      b.status.toLowerCase() != 'paid' &&
                                      b.dueDate.year == day.year &&
                                      b.dueDate.month == day.month &&
                                      b.dueDate.day == day.day,
                                );

                                return Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      AppHaptics.selectionClick();
                                      setState(
                                        () => _selectedCalendarDay = day,
                                      );
                                    },
                                    child: Container(
                                      height: 57,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? colors.textPrimary
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            dayLetter,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 12,
                                              color: isSelected
                                                  ? colors.onPrimaryButton
                                                  : colors.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${day.day}',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? colors.onPrimaryButton
                                                  : colors.textPrimary,
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
                                                    ? colors.onPrimaryButton
                                                    : colors.danger,
                                                borderRadius:
                                                    BorderRadius.circular(2),
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
                              color: colors.divider,
                            ),
                            const SizedBox(height: 12),

                            // Upcoming Bill Item (Node 82:574)
                            if (billsAsync.hasError && bills.isEmpty) ...[
                              KasyabaErrorCard(
                                message: friendlyErrorMessage(
                                  billsAsync.error,
                                  fallback: 'Could not load upcoming bills.',
                                ),
                                onRetry: () => ref.invalidate(billsProvider),
                              ),
                            ] else if (billsAsync.isLoading &&
                                bills.isEmpty) ...[
                              const KasyabaLoadingSkeleton(lines: 2),
                            ] else if (weekBills.isNotEmpty) ...[
                              _buildBillItemRow(weekBills.first),
                            ] else ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No upcoming bills this week',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color:
                                        colors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Activity Section (Node 82:583) ──────────────────────────
                FadeSlideEntrance.staggered(
                  index: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Activity',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => context.push('/transactions/add'),
                            child: Container(
                              height: 36,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: colors.textPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  ColorFiltered(
                                    colorFilter: ColorFilter.mode(
                                      colors.onPrimaryButton,
                                      BlendMode.srcIn,
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/images/activity_add.svg',
                                      width: 18,
                                      height: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Add transaction',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: colors.onPrimaryButton,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // 3-Way Physical Sliding Filter Pill: All / Expenses / Income (Node 82:588)
                      SlidingSegmentedPill(
                        items: const ['All', 'Expenses', 'Income'],
                        selectedIndex: switch (_activeFilter) {
                          'Expenses' => 1,
                          'Income' => 2,
                          _ => 0,
                        },
                        onChanged: (idx) {
                          setState(() {
                            _activeFilter = switch (idx) {
                              1 => 'Expenses',
                              2 => 'Income',
                              _ => 'All',
                            };
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grouped Daily Transactions List (Node 82:597) ───────────
                FadeSlideEntrance.staggered(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (paginatedAsync.hasError && transactions.isEmpty) ...[
                        if (!isOnline)
                          const NeedsInternetNotice(
                            message:
                                "This month isn't saved on this device — reconnect to load it.",
                          )
                        else
                          KasyabaErrorCard(
                            message: friendlyErrorMessage(
                              paginatedAsync.error,
                              fallback: 'Could not load transactions.',
                            ),
                            onRetry: () =>
                                ref.invalidate(paginatedTransactionsProvider),
                          ),
                      ] else if (paginatedAsync.isLoading &&
                          transactions.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: colors.textPrimary,
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
                                color: colors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ] else ...[
                        ...sortedGroupKeys.map((groupKey) {
                          final groupItems = groupedTransactions[groupKey]!;
                          final firstDate = groupItems.first.date;
                          final groupHeaderDate = _formatGroupHeaderDate(
                            firstDate,
                          );

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
                          final netSign = isNetPositive
                              ? '+'
                              : (isNetNegative ? '−' : '');
                          final netFormatted =
                              '$netSign${CurrencyFormatter.format(dailyNet.abs())}';

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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        groupHeaderDate,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.0,
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                      Text(
                                        netFormatted,
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isNetPositive
                                              ? colors.success
                                              : (isNetNegative
                                                    ? colors.textSecondary
                                                    : colors.textSecondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Transactions Card Container (Node 82:601)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.card,
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: colors.cardBorder,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 3,
                                    ),
                                    itemCount: groupItems.length,
                                    separatorBuilder: (_, _) => Container(
                                      height: 1,
                                      color: colors.divider,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bill Item Row (Node 82:574) ───────────────────────────────────────────
  Widget _buildBillItemRow(BillItem bill) {
    final colors = context.kColors;
    final dueFormatted = DateFormat('EEE, MMM d').format(bill.dueDate);
    final recurrenceLabel = _billRecurrenceLabel(bill.recurrence);
    final scheduleLabel = recurrenceLabel == null
        ? dueFormatted
        : '$dueFormatted · $recurrenceLabel';
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
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scheduleLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: colors.textSecondary,
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
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: colors.danger,
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
    final colors = context.kColors;
    final isExpense = t.isExpense;
    final isTransfer = t.isTransfer;
    final amountSign = isExpense ? '−' : (isTransfer ? '' : '+');
    final amountColor = isExpense
        ? colors.danger
        : (isTransfer
              ? colors.textPrimary
              : colors.success);

    return SpringTouch(
      scaleDown: 0.98,
      onTap: () => _showTransactionActions(context, ref, t),
      onLongPress: () => _showTransactionActions(context, ref, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            // Squircle Category Icon (Node 82:604)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.canvas.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: colors.cardBorderStrong, width: 1),
              ),
              alignment: Alignment.center,
              child: Icon(
                CategoryIconHelper.getIcon(t.categoryName),
                size: 20,
                color: colors.textPrimary,
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
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: colors.textSecondary,
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
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final formatted = DateFormat('MMM d').format(date).toUpperCase();
    return isToday ? 'TODAY · $formatted' : formatted;
  }
}
