import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../app/theme/app_theme.dart';

Future<void> _showTransactionActions(
  BuildContext context,
  WidgetRef ref,
  TransactionEntry transaction,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!transaction.isTransfer)
            ListTile(
              leading: const Icon(Icons.edit_rounded),
              title: const Text('Edit transaction'),
              onTap: () => Navigator.of(sheetContext).pop('edit'),
            ),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(
              transaction.isTransfer ? 'Delete transfer' : 'Delete transaction',
            ),
            textColor: AppColors.expense,
            iconColor: AppColors.expense,
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
      title: Text(
        transaction.isTransfer ? 'Delete transfer?' : 'Delete transaction?',
      ),
      content: Text(
        transaction.isTransfer
            ? 'This will restore the money to the source account and remove it from the destination account.'
            : 'This will remove it from your balances and reports.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (!context.mounted || confirmed != true) return;

  try {
    await ref.read(transactionMutatorProvider).deleteTransaction(transaction);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction deleted.')));
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not delete the transaction.')),
    );
  }
}

Future<void> _showNewEntryMenu(BuildContext context) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.receipt_long_rounded),
            title: const Text('Income or expense'),
            subtitle: const Text('Record money in or money out'),
            onTap: () => Navigator.of(sheetContext).pop('transaction'),
          ),
          ListTile(
            leading: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Transfer between accounts'),
            subtitle: const Text('Move money without changing net worth'),
            onTap: () => Navigator.of(sheetContext).pop('transfer'),
          ),
        ],
      ),
    ),
  );
  if (!context.mounted || action == null) return;
  context.push(action == 'transfer' ? '/transfers/add' : '/transactions/add');
}

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(transactionFilterProvider);
    final paginatedAsync = ref.watch(paginatedTransactionsProvider);

    void clearDateFilter() {
      ref.read(transactionFilterProvider.notifier).state = filter.copyWith(
        clearDates: true,
        page: 1,
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.lightBg,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          _TransactionsSliverAppBar(
            isDark: isDark,
            filter: filter,
            onRefresh: () => ref.invalidate(paginatedTransactionsProvider),
            onPickDateRange: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100, 12, 31),
                initialDateRange:
                    filter.fromDate != null && filter.toDate != null
                    ? DateTimeRange(
                        start: filter.fromDate!,
                        end: filter.toDate!,
                      )
                    : null,
                builder: (context, child) {
                  return Theme(
                    data: theme.copyWith(
                      colorScheme: isDark
                          ? const ColorScheme.dark(
                              primary: AppColors.emerald500,
                              onPrimary: Colors.white,
                              surface: AppColors.surface800,
                              onSurface: Colors.white,
                            )
                          : const ColorScheme.light(
                              primary: AppColors.emerald500,
                              onPrimary: Colors.white,
                            ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                ref.read(transactionFilterProvider.notifier).state = filter
                    .copyWith(
                      fromDate: picked.start,
                      toDate: picked.end,
                      page: 1,
                    );
              }
            },
          ),
        ],
        body: RefreshIndicator(
          color: AppColors.emerald500,
          backgroundColor: isDark ? AppColors.surface800 : Colors.white,
          onRefresh: () async => ref.invalidate(paginatedTransactionsProvider),
          child: Column(
            children: [
              // ── Active Date Filter Chip Banner ─────────────────
              if (filter.fromDate != null || filter.toDate != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.zero,
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: AppColors.emerald500,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatRangeLabel(filter.fromDate, filter.toDate),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Tooltip(
                              message: 'Clear date filter',
                              child: Semantics(
                                button: true,
                                label: 'Clear date filter',
                                onTap: clearDateFilter,
                                excludeSemantics: true,
                                child: InkWell(
                                  onTap: clearDateFilter,
                                  customBorder: const CircleBorder(),
                                  child: const SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: Center(
                                      child: Icon(
                                        Icons.cancel_rounded,
                                        size: 16,
                                        color: AppColors.emerald500,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Main Transaction Content ───────────────────────
              Expanded(
                child: paginatedAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.emerald500,
                    ),
                  ),
                  error: (err, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: ModernCard(
                        padding: const EdgeInsets.all(20),
                        borderColor: AppColors.expense.withValues(alpha: 0.4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.expense,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load transactions',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              friendlyErrorMessage(err),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedL,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  ref.invalidate(paginatedTransactionsProvider),
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  data: (paginated) {
                    if (paginated.items.isEmpty) {
                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          ModernCard(
                            child: EmptyStateView(
                              title: 'No Transactions Found',
                              message: filter.fromDate != null
                                  ? 'No activity found for the selected date range.'
                                  : 'Your income and expenses will appear here.',
                              icon: Icons.swap_horiz_outlined,
                              actionLabel: 'Add Transaction',
                              onAction: () => context.go('/transactions/add'),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        // List items
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                            itemCount: paginated.items.length,
                            itemBuilder: (context, index) {
                              final item = paginated.items[index];
                              final isExpense = item.isExpense;
                              final color = item.isTransfer
                                  ? AppColors.gold500
                                  : isExpense
                                  ? AppColors.expense
                                  : AppColors.income;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ModernCard(
                                  onTap: () => _showTransactionActions(
                                    context,
                                    ref,
                                    item,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: color.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.zero,
                                            border: Border.all(
                                              color: color.withValues(
                                                alpha: 0.30,
                                              ),
                                              width: 1,
                                            ),
                                          ),
                                          child: Icon(
                                            item.isTransfer
                                                ? Icons.swap_horiz_rounded
                                                : isExpense
                                                ? Icons.arrow_upward_rounded
                                                : Icons.arrow_downward_rounded,
                                            color: color,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 14),

                                        // Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: isDark
                                                      ? AppColors.textDark
                                                      : AppColors.textLight,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                '${item.isCancelled
                                                    ? 'Cancelled • '
                                                    : item.isScheduled
                                                    ? 'Planned • '
                                                    : ''}${item.categoryName} • ${DateFormat('MMM d, yyyy').format(item.date)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? AppColors.textMuted
                                                      : AppColors.textMutedL,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Amount
                                        Text(
                                          '${item.isTransfer
                                              ? '↔'
                                              : isExpense
                                              ? '–'
                                              : '+'}₱${item.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: -0.3,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // ── Pagination Bar Controls ──────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surface800 : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.05,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: ${paginated.totalCount} entries',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.textMutedL,
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                      ),
                                      onPressed: paginated.hasPrevPage
                                          ? () {
                                              ref
                                                  .read(
                                                    transactionFilterProvider
                                                        .notifier,
                                                  )
                                                  .state = filter.copyWith(
                                                page: paginated.page - 1,
                                              );
                                            }
                                          : null,
                                      tooltip: 'Previous Page',
                                    ),
                                    Text(
                                      'Page ${paginated.page} of ${paginated.totalPages}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textLight,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                      ),
                                      onPressed: paginated.hasNextPage
                                          ? () {
                                              ref
                                                  .read(
                                                    transactionFilterProvider
                                                        .notifier,
                                                  )
                                                  .state = filter.copyWith(
                                                page: paginated.page + 1,
                                              );
                                            }
                                          : null,
                                      tooltip: 'Next Page',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
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
          onPressed: () => _showNewEntryMenu(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          icon: const Icon(Icons.add_rounded, size: 22, color: Colors.black),
          label: const Text(
            'New',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          tooltip: 'Add Transaction',
        ),
      ),
    );
  }

  String _formatRangeLabel(DateTime? start, DateTime? end) {
    if (start != null && end != null) {
      return '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d, yyyy').format(end)}';
    }
    if (start != null) return 'From ${DateFormat('MMM d, yyyy').format(start)}';
    if (end != null) return 'Until ${DateFormat('MMM d, yyyy').format(end)}';
    return 'All Time';
  }
}

class _TransactionsSliverAppBar extends StatelessWidget {
  final bool isDark;
  final TransactionQueryFilter filter;
  final VoidCallback onRefresh;
  final VoidCallback onPickDateRange;

  const _TransactionsSliverAppBar({
    required this.isDark,
    required this.filter,
    required this.onRefresh,
    required this.onPickDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final hasDateFilter = filter.fromDate != null || filter.toDate != null;

    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: AppColors.obsidian,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text(
        'Transactions',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 22,
          letterSpacing: 0.5,
          color: AppColors.textDark,
        ),
      ),
      titleSpacing: 20,
      actions: [
        _AppBarIconBtn(
          icon: Icons.calendar_month_rounded,
          isDark: isDark,
          isActive: hasDateFilter,
          onTap: onPickDateRange,
          tooltip: 'Filter by Date',
        ),
        const SizedBox(width: 8),
        _AppBarIconBtn(
          icon: Icons.refresh_rounded,
          isDark: isDark,
          onTap: onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _AppBarIconBtn extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final bool isActive;
  final VoidCallback onTap;
  final String tooltip;

  const _AppBarIconBtn({
    required this.icon,
    required this.isDark,
    this.isActive = false,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    color: isActive
                        ? AppColors.emerald500.withValues(alpha: 0.2)
                        : AppColors.surface700,
                    border: Border.all(
                      color: isActive
                          ? AppColors.emerald500
                          : const Color(0xFF1F293D),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isActive
                        ? AppColors.emerald500
                        : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
