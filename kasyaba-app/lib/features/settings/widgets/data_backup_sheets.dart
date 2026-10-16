import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/data_export_helper.dart';

/// Shows the modal bottom sheet to export a full JSON backup.
Future<void> showExportBackupSheet(BuildContext context, WidgetRef ref) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.emerald500),
    ),
  );

  try {
    final data = await ref.read(authProvider.notifier).exportData();
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Dismiss loading indicator

    final validation = DataExportHelper.validateBackup(data);
    final jsonPretty = const JsonEncoder.withIndent('  ').convert(data);

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ExportBackupSheet(
        data: data,
        jsonPretty: jsonPretty,
        validation: validation,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Dismiss loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          friendlyErrorMessage(
            e,
            fallback: 'Failed to export financial backup.',
          ),
        ),
      ),
    );
  }
}

/// Shows the modal bottom sheet to import / restore a JSON backup.
Future<void> showRestoreBackupSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    builder: (ctx) => const _RestoreBackupSheet(),
  );
}

/// Shows the modal bottom sheet to export all transactions to CSV.
Future<void> showExportCsvSheet(BuildContext context, WidgetRef ref) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: AppColors.gold500),
    ),
  );

  try {
    final paginated = await ref.read(paginatedTransactionsProvider.future);
    final accounts = await ref.read(accountsProvider.future);
    if (!context.mounted) return;
    Navigator.of(context).pop(); // Dismiss loader

    final accountMap = {for (final a in accounts) a.id: a.name};
    final transactions = paginated.items;
    final csv = DataExportHelper.generateTransactionsCsv(
      transactions: transactions,
      accountNames: accountMap,
    );

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) => _ExportCsvSheet(
        transactions: transactions,
        csvContent: csv,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          friendlyErrorMessage(
            e,
            fallback: 'Failed to compile transactions for CSV export.',
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 1. Export Backup Sheet
// ─────────────────────────────────────────────────────────────

class _ExportBackupSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  final String jsonPretty;
  final BackupValidationResult validation;

  const _ExportBackupSheet({
    required this.data,
    required this.jsonPretty,
    required this.validation,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final formattedTime = DateFormat('MMM d, yyyy h:mm a').format(now);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 +
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface900.withValues(alpha: 0.95)
                : AppColors.lightCard.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface600
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.cloud_download_rounded,
                        color: Color(0xFF38BDF8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Export Backup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PORTABLE JSON',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF38BDF8),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Snapshot generated $formattedTime',
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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Record Counts Grid Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface800 : AppColors.lightCard2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.subtleBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BACKUP PAYLOAD CONTENTS',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textMutedL,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetricPill(
                            label: 'Wallets',
                            count: validation.accountCount,
                            color: const Color(0xFF10B981),
                          ),
                          _MetricPill(
                            label: 'Expenses',
                            count: validation.expenseCount,
                            color: AppColors.expense,
                          ),
                          _MetricPill(
                            label: 'Income',
                            count: validation.incomeCount,
                            color: AppColors.income,
                          ),
                          _MetricPill(
                            label: 'Transfers',
                            count: validation.transferCount,
                            color: const Color(0xFF38BDF8),
                          ),
                          _MetricPill(
                            label: 'Goals',
                            count: validation.goalCount,
                            color: const Color(0xFFD4AF37),
                          ),
                          _MetricPill(
                            label: 'Budgets',
                            count: validation.budgetCount,
                            color: const Color(0xFFA855F7),
                          ),
                          _MetricPill(
                            label: 'Bills',
                            count: validation.billCount,
                            color: const Color(0xFFF97316),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: 15,
                            color: AppColors.emerald400,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Account: ${validation.userEmail ?? "Signed-in user"} • Total records: ${validation.totalRecordsCount}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final timestamp =
                          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                      final filename = 'kasyaba_backup_$timestamp.json';
                      final path = await DataExportHelper.saveToFile(
                        filename: filename,
                        content: jsonPretty,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Backup saved to: $path'),
                            backgroundColor: const Color(0xFF0284C7),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save file: $err'),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Save Backup File to Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: jsonPretty));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Backup JSON copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy JSON to Clipboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.textLight,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.surface600
                          : AppColors.lightBorder,
                    ),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 2. Import / Restore Backup Sheet
// ─────────────────────────────────────────────────────────────

class _RestoreBackupSheet extends ConsumerStatefulWidget {
  const _RestoreBackupSheet();

  @override
  ConsumerState<_RestoreBackupSheet> createState() =>
      _RestoreBackupSheetState();
}

class _RestoreBackupSheetState extends ConsumerState<_RestoreBackupSheet> {
  final _jsonController = TextEditingController();
  BackupValidationResult? _validationResult;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    _jsonController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final text = _jsonController.text.trim();
    if (text.isEmpty) {
      setState(() => _validationResult = null);
      return;
    }
    final res = DataExportHelper.validateBackup(text);
    setState(() => _validationResult = res);
  }

  @override
  void dispose() {
    _jsonController.removeListener(_onTextChanged);
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _handleRestore() async {
    final res = _validationResult;
    if (res == null || !res.isValid || res.sanitizedPayload == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Restore'),
        content: Text(
          'This will restore ${res.totalRecordsCount} records (${res.accountCount} wallets, ${res.expenseCount} expenses, ${res.incomeCount} incomes) into your active ledger.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald500,
            ),
            child: const Text('Restore Now'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    try {
      final restoreRes = await ref
          .read(authProvider.notifier)
          .restoreData(res.sanitizedPayload!);

      // Invalidate all providers to reflect the freshly restored data
      ref.invalidate(accountsProvider);
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(paginatedTransactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(billsProvider);
      ref.invalidate(budgetStatusProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Backup restored! ${restoreRes["counts"]?["accounts"] ?? res.accountCount} wallets and ${restoreRes["counts"]?["expenses"] ?? res.expenseCount} expenses synchronized.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.emerald500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                e,
                fallback: 'Failed to restore backup payload.',
              ),
            ),
            backgroundColor: AppColors.expense,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final res = _validationResult;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 +
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface900.withValues(alpha: 0.95)
                : AppColors.lightCard.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface600
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_rounded,
                        color: AppColors.emerald400,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Import Backup',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald500
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SCHEMA VALIDATED',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.emerald400,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Restore your complete ledger offline or online',
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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // JSON Input Text Area
                Text(
                  'PASTE BACKUP JSON',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _jsonController,
                  maxLines: 5,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white : AppColors.textLight,
                  ),
                  decoration: InputDecoration(
                    hintText: '{\n  "exportedAt": "...",\n  "user": { ... }\n}',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? AppColors.surface500 : AppColors.textMutedL,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surface800
                        : AppColors.lightCard2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark
                            ? AppColors.surface700
                            : AppColors.lightBorder,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                // Live Validation Feedback
                if (res == null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface800
                          : AppColors.lightCard2,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.subtleBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textMutedL,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Paste your Kasyaba JSON backup above. It will be verified against our strict deterministic schema before restoring.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedL,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (!res.isValid)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.expense.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.expense.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 18,
                          color: Color(0xFFF87171),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            res.errorMessage ?? 'Invalid backup format.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFF87171),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: AppColors.emerald400,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Valid Backup Detected (${res.totalRecordsCount} records)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.emerald400,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MetricPill(
                              label: 'Wallets',
                              count: res.accountCount,
                              color: const Color(0xFF10B981),
                            ),
                            _MetricPill(
                              label: 'Expenses',
                              count: res.expenseCount,
                              color: AppColors.expense,
                            ),
                            _MetricPill(
                              label: 'Income',
                              count: res.incomeCount,
                              color: AppColors.income,
                            ),
                            _MetricPill(
                              label: 'Transfers',
                              count: res.transferCount,
                              color: const Color(0xFF38BDF8),
                            ),
                            _MetricPill(
                              label: 'Goals',
                              count: res.goalCount,
                              color: const Color(0xFFD4AF37),
                            ),
                            _MetricPill(
                              label: 'Budgets',
                              count: res.budgetCount,
                              color: const Color(0xFFA855F7),
                            ),
                            _MetricPill(
                              label: 'Bills',
                              count: res.billCount,
                              color: const Color(0xFFF97316),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // Restore Button
                ElevatedButton.icon(
                  onPressed: (_validationResult?.isValid == true && !_isRestoring)
                      ? _handleRestore
                      : null,
                  icon: _isRestoring
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(
                    _isRestoring ? 'Restoring Ledger...' : 'Restore & Sync Backup',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emerald500,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: isDark
                        ? AppColors.surface700
                        : AppColors.lightCard2,
                    disabledForegroundColor: AppColors.textMuted,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 3. Export CSV Sheet
// ─────────────────────────────────────────────────────────────

class _ExportCsvSheet extends StatelessWidget {
  final List<TransactionEntry> transactions;
  final String csvContent;

  const _ExportCsvSheet({
    required this.transactions,
    required this.csvContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalCount = transactions.length;

    DateTime? earliest;
    DateTime? latest;
    for (final t in transactions) {
      if (earliest == null || t.date.isBefore(earliest)) earliest = t.date;
      if (latest == null || t.date.isAfter(latest)) latest = t.date;
    }

    final dateRangeStr = (earliest != null && latest != null)
        ? '${DateFormat("MMM d, yyyy").format(earliest)} – ${DateFormat("MMM d, yyyy").format(latest)}'
        : 'All time';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.92,
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 +
                MediaQuery.viewInsetsOf(context).bottom +
                MediaQuery.paddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surface900.withValues(alpha: 0.95)
                : AppColors.lightCard.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surface600
                          : AppColors.lightBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.table_chart_rounded,
                        color: Color(0xFFFBBF24),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Export to CSV',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'SPREADSHEET READY',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFBBF24),
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Compatible with Excel, Google Sheets & Numbers',
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
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Metrics Box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface800 : AppColors.lightCard2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.subtleBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Transactions:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedL,
                            ),
                          ),
                          Text(
                            '$totalCount entries',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              fontFeatures: CurrencyFormatter.tabularFigures,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Date Coverage:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedL,
                            ),
                          ),
                          Text(
                            dateRangeStr,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'CSV Schema:',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedL,
                            ),
                          ),
                          const Text(
                            'RFC 4180 (8 Columns)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFBBF24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final timestamp =
                          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
                      final filename = 'kasyaba_transactions_$timestamp.csv';
                      final path = await DataExportHelper.saveToFile(
                        filename: filename,
                        content: csvContent,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('CSV saved to: $path'),
                            backgroundColor: const Color(0xFFD97706),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save CSV: $err'),
                            backgroundColor: AppColors.expense,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.file_download_rounded, size: 18),
                  label: const Text('Save CSV File to Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: csvContent));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('CSV content copied to clipboard!'),
                          backgroundColor: Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('Copy CSV to Clipboard'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : AppColors.textLight,
                    side: BorderSide(
                      color: isDark
                          ? AppColors.surface600
                          : AppColors.lightBorder,
                    ),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Metric Pill Widget
// ─────────────────────────────────────────────────────────────

class _MetricPill extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _MetricPill({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        '$count $label',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFeatures: CurrencyFormatter.tabularFigures,
          color: color,
        ),
      ),
    );
  }
}
