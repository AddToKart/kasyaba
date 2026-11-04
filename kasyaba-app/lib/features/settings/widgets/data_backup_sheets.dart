import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/data_export_helper.dart';
import '../../../shared/widgets/app_dialog.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/pill_button.dart';

const String lastBackupAtKey = 'last_backup_at';

Future<void> showExportBackupSheet(
  BuildContext context,
  WidgetRef ref, {
  Map<String, dynamic>? initialData,
}) async {
  await showKasyabaSheet<void>(
    context: context,
    builder: (ctx) => _ExportBackupSheet(initialData: initialData),
  );
}

Future<void> showRestoreBackupSheet(BuildContext context, WidgetRef ref) async {
  await showKasyabaSheet<void>(
    context: context,
    builder: (ctx) => const _RestoreBackupSheet(),
  );
}

Future<void> showExportCsvSheet(
  BuildContext context,
  WidgetRef ref, {
  List<TransactionEntry>? initialTransactions,
  String? initialCsvContent,
}) async {
  await showKasyabaSheet<void>(
    context: context,
    builder: (ctx) => _ExportCsvSheet(
      initialTransactions: initialTransactions,
      initialCsvContent: initialCsvContent,
    ),
  );
}

Future<void> _recordBackupTimestamp(WidgetRef ref) async {
  try {
    await ref
        .read(secureStorageProvider)
        .writeRaw(lastBackupAtKey, DateTime.now().toIso8601String());
  } catch (_) {
    return;
  }
}

class _ExportBackupSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialData;

  const _ExportBackupSheet({this.initialData});

  @override
  ConsumerState<_ExportBackupSheet> createState() => _ExportBackupSheetState();
}

class _ExportBackupSheetState extends ConsumerState<_ExportBackupSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String? _jsonPretty;
  BackupValidationResult? _validation;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _validation = DataExportHelper.validateBackup(widget.initialData!);
      _jsonPretty = const JsonEncoder.withIndent(
        '  ',
      ).convert(widget.initialData!);
      _isLoading = false;
    } else {
      _loadBackup();
    }
  }

  Future<void> _loadBackup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref.read(authProvider.notifier).exportData();
      final validation = DataExportHelper.validateBackup(data);
      final jsonPretty = const JsonEncoder.withIndent('  ').convert(data);

      if (mounted) {
        setState(() {
          _validation = validation;
          _jsonPretty = jsonPretty;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = friendlyErrorMessage(
            error,
            fallback: 'Failed to export financial backup.',
          );
        });
      }
    }
  }

  Future<void> _saveFile(String content) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'kasyaba_backup_$timestamp.json';
      final path = await DataExportHelper.saveToFile(
        filename: filename,
        content: content,
      );
      await _recordBackupTimestamp(ref);
      if (!mounted) return;
      KasyabaToast.showSuccess(context, 'Backup saved.', subtitle: path);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Could not save the backup file. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copyJson(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      // Clipboard copies are not backups; timestamps are only recorded when a
      // backup file is actually saved to the device.
      if (!mounted) return;
      KasyabaToast.showSuccess(context, 'Backup JSON copied to clipboard.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Could not copy the backup. Please try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedTime = DateFormat('MMM d, yyyy h:mm a').format(now);
    final validation = _validation;
    final jsonPretty = _jsonPretty;

    return AppSheet(
      color: KasyabaTokens.ebony,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                icon: Icons.cloud_download_rounded,
                accent: KasyabaTokens.poloBlue,
                title: 'Export Backup',
                badge: 'PORTABLE JSON',
                subtitle: 'Snapshot generated $formattedTime',
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                Column(
                  children: [
                    const KasyabaLoadingSkeleton(lines: 4),
                    const SizedBox(height: 16),
                    Text(
                      'Compiling complete account snapshot...',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: KasyabaTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ],
                )
              else if (_errorMessage != null)
                KasyabaErrorCard(message: _errorMessage!, onRetry: _loadBackup)
              else if (validation != null && jsonPretty != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.bigStone,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: KasyabaTokens.poloBlue22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BACKUP PAYLOAD CONTENTS',
                        style: GoogleFonts.dmSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: KasyabaTokens.periwinkleGraySubtitle,
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
                            color: KasyabaTokens.poloBlue,
                          ),
                          _MetricPill(
                            label: 'Expenses',
                            count: validation.expenseCount,
                            color: KasyabaTokens.apricot,
                          ),
                          _MetricPill(
                            label: 'Income',
                            count: validation.incomeCount,
                            color: KasyabaTokens.bermuda,
                          ),
                          _MetricPill(
                            label: 'Transfers',
                            count: validation.transferCount,
                            color: KasyabaTokens.java,
                          ),
                          _MetricPill(
                            label: 'Goals',
                            count: validation.goalCount,
                            color: KasyabaTokens.casablanca,
                          ),
                          _MetricPill(
                            label: 'Budgets',
                            count: validation.budgetCount,
                            color: KasyabaTokens.cornflowerBlue,
                          ),
                          _MetricPill(
                            label: 'Bills',
                            count: validation.billCount,
                            color: KasyabaTokens.baliHai,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 15,
                            color: KasyabaTokens.bermuda,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Account: ${validation.userEmail ?? "Signed-in user"} • Total records: ${validation.totalRecordsCount}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: KasyabaTokens.periwinkleGraySubtitle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: 'Save Backup File to Device',
                  icon: Icons.download_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : () => _saveFile(jsonPretty),
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'Copy JSON to Clipboard',
                  icon: Icons.copy_rounded,
                  variant: PillButtonVariant.secondary,
                  onPressed: () => _copyJson(jsonPretty),
                ),
              ],
            ],
          ),
    );
  }
}

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

    final confirmed = await showKasyabaConfirmDialog(
      context,
      title: 'Confirm Restore',
      message:
          'This will restore ${res.totalRecordsCount} records (${res.accountCount} wallets, ${res.expenseCount} expenses, ${res.incomeCount} incomes) into your active ledger.\n\nProceed?',
      confirmLabel: 'Restore Now',
    );

    if (confirmed != true) return;

    setState(() => _isRestoring = true);

    try {
      final restoreRes = await ref
          .read(authProvider.notifier)
          .restoreData(res.sanitizedPayload!);

      ref.invalidate(accountsProvider);
      ref.invalidate(accountBalancesProvider);
      ref.invalidate(paginatedTransactionsProvider);
      ref.invalidate(dashboardProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(goalsProvider);
      ref.invalidate(goalDetailProvider);
      ref.invalidate(billsProvider);
      ref.invalidate(budgetStatusProvider);
      ref.invalidate(planningProvider);
      ref.invalidate(alertsProvider);

      if (mounted) {
        KasyabaToast.showSuccess(
          context,
          'Backup restored.',
          subtitle:
              '${restoreRes["counts"]?["accounts"] ?? res.accountCount} wallets and ${restoreRes["counts"]?["expenses"] ?? res.expenseCount} expenses synchronized.',
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isRestoring = false);
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Failed to restore backup payload.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = _validationResult;

    return AppSheet(
      color: KasyabaTokens.ebony,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(
                icon: Icons.cloud_upload_rounded,
                accent: KasyabaTokens.bermuda,
                title: 'Import Backup',
                badge: 'SCHEMA VALIDATED',
                subtitle: 'Restore your complete ledger offline or online',
              ),
              const SizedBox(height: 16),
              Text(
                'PASTE BACKUP JSON',
                style: GoogleFonts.dmSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: KasyabaTokens.periwinkleGraySubtitle,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _jsonController,
                maxLines: 5,
                style: GoogleFonts.robotoMono(
                  fontSize: 12,
                  color: KasyabaTokens.periwinkleGray,
                ),
                decoration: InputDecoration(
                  hintText: '{\n  "exportedAt": "...",\n  "user": { ... }\n}',
                  hintStyle: GoogleFonts.robotoMono(
                    fontSize: 12,
                    color: KasyabaTokens.poloBlue40,
                  ),
                  filled: true,
                  fillColor: KasyabaTokens.bigStone,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: KasyabaTokens.poloBlue22,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: KasyabaTokens.poloBlue22,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(
                      color: KasyabaTokens.poloBlue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              if (res == null)
                _ValidationCard(
                  background: KasyabaTokens.bigStone,
                  border: KasyabaTokens.poloBlue22,
                  icon: Icons.info_outline_rounded,
                  iconColor: KasyabaTokens.periwinkleGraySubtitle,
                  title: null,
                  titleColor: KasyabaTokens.periwinkleGray,
                  message:
                      'Paste your Kasyaba JSON backup above. It will be verified against our strict deterministic schema before restoring.',
                  messageColor: KasyabaTokens.periwinkleGraySubtitle,
                )
              else if (!res.isValid)
                _ValidationCard(
                  background: KasyabaTokens.apricot15,
                  border: KasyabaTokens.apricot.withValues(alpha: 0.55),
                  icon: Icons.error_outline_rounded,
                  iconColor: KasyabaTokens.apricot,
                  title: null,
                  titleColor: KasyabaTokens.apricot,
                  message: res.errorMessage ?? 'Invalid backup format.',
                  messageColor: KasyabaTokens.apricot,
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.bermuda15,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: KasyabaTokens.bermuda.withValues(alpha: 0.55),
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
                            color: KasyabaTokens.bermuda,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Valid Backup Detected (${res.totalRecordsCount} records)',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: KasyabaTokens.bermuda,
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
                            color: KasyabaTokens.poloBlue,
                          ),
                          _MetricPill(
                            label: 'Expenses',
                            count: res.expenseCount,
                            color: KasyabaTokens.apricot,
                          ),
                          _MetricPill(
                            label: 'Income',
                            count: res.incomeCount,
                            color: KasyabaTokens.bermuda,
                          ),
                          _MetricPill(
                            label: 'Transfers',
                            count: res.transferCount,
                            color: KasyabaTokens.java,
                          ),
                          _MetricPill(
                            label: 'Goals',
                            count: res.goalCount,
                            color: KasyabaTokens.casablanca,
                          ),
                          _MetricPill(
                            label: 'Budgets',
                            count: res.budgetCount,
                            color: KasyabaTokens.cornflowerBlue,
                          ),
                          _MetricPill(
                            label: 'Bills',
                            count: res.billCount,
                            color: KasyabaTokens.baliHai,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              PillButton(
                label: _isRestoring
                    ? 'Restoring Ledger...'
                    : 'Restore & Sync Backup',
                icon: Icons.sync_rounded,
                isLoading: _isRestoring,
                onPressed: (_validationResult?.isValid == true && !_isRestoring)
                    ? _handleRestore
                    : null,
              ),
             ],
           ),
     );
  }
}

class _ExportCsvSheet extends ConsumerStatefulWidget {
  final List<TransactionEntry>? initialTransactions;
  final String? initialCsvContent;

  const _ExportCsvSheet({this.initialTransactions, this.initialCsvContent});

  @override
  ConsumerState<_ExportCsvSheet> createState() => _ExportCsvSheetState();
}

class _ExportCsvSheetState extends ConsumerState<_ExportCsvSheet> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<TransactionEntry> _transactions = const [];
  String _csvContent = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTransactions != null &&
        widget.initialCsvContent != null) {
      _transactions = widget.initialTransactions!;
      _csvContent = widget.initialCsvContent!;
      _isLoading = false;
    } else {
      _loadCsv();
    }
  }

  DateTime _parseDate(dynamic value) {
    final raw = value?.toString() ?? '';
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
    if (match != null) {
      return DateTime(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }

  TransactionEntry _mapTransaction(Map<String, dynamic> item) {
    final type = item['type']?.toString() ?? 'expense';
    return TransactionEntry(
      id: item['id']?.toString() ?? '',
      title: item['title']?.toString() ?? 'Transaction',
      amount: double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0,
      isExpense: type == 'expense',
      date: _parseDate(item['date']),
      categoryName: item['categoryName']?.toString() ?? 'Transaction',
      type: type,
      status: item['status']?.toString() ?? 'posted',
      accountId: item['accountId']?.toString(),
      categoryId: item['categoryId']?.toString(),
      notes: item['notes']?.toString(),
    );
  }

  Future<void> _loadCsv() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final accounts = await ref.read(accountsProvider.future);
      final accountMap = {for (final a in accounts) a.id: a.name};

      const pageSize = 500;
      var page = 1;
      var totalCount = 0;
      final all = <TransactionEntry>[];
      final seenIds = <String>{};

      while (true) {
        final response = await dio.get(
          '/transactions',
          queryParameters: {'page': page, 'limit': pageSize},
        );
        final rawItems = response.data['data'] as List<dynamic>? ?? const [];
        final items = rawItems
            .whereType<Map<String, dynamic>>()
            .map(_mapTransaction)
            .toList();
        var added = 0;
        for (final item in items) {
          if (seenIds.add(item.id)) {
            all.add(item);
            added++;
          }
        }
        totalCount =
            (response.data['meta']?['total'] as num?)?.toInt() ?? all.length;

        if (items.isEmpty ||
            items.length < pageSize ||
            all.length >= totalCount ||
            added == 0) {
          break;
        }
        page++;
      }

      final csv = DataExportHelper.generateTransactionsCsv(
        transactions: all,
        accountNames: accountMap,
      );

      if (mounted) {
        setState(() {
          _transactions = all;
          _csvContent = csv;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = friendlyErrorMessage(
            error,
            fallback: 'Failed to compile transactions for CSV export.',
          );
        });
      }
    }
  }

  Future<void> _saveCsv(String content) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'kasyaba_transactions_$timestamp.csv';
      final path = await DataExportHelper.saveToFile(
        filename: filename,
        content: content,
      );
      if (!mounted) return;
      KasyabaToast.showSuccess(context, 'CSV saved.', subtitle: path);
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Could not save the CSV file. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _copyCsv(String content) async {
    try {
      await Clipboard.setData(ClipboardData(text: content));
      if (!mounted) return;
      KasyabaToast.showSuccess(context, 'CSV content copied to clipboard.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback: 'Could not copy the CSV. Please try again.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactions = _transactions;
    final csvContent = _csvContent;
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

    return AppSheet(
      color: KasyabaTokens.ebony,
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 +
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(
                icon: Icons.table_chart_rounded,
                accent: KasyabaTokens.casablanca,
                title: 'Export to CSV',
                badge: 'SPREADSHEET READY',
                subtitle: 'Compatible with Excel, Google Sheets & Numbers',
              ),
              const SizedBox(height: 18),
              if (_isLoading)
                Column(
                  children: [
                    const KasyabaLoadingSkeleton(lines: 4),
                    const SizedBox(height: 16),
                    Text(
                      'Compiling transaction ledger...',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: KasyabaTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ],
                )
              else if (_errorMessage != null)
                KasyabaErrorCard(message: _errorMessage!, onRetry: _loadCsv)
              else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.bigStone,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: KasyabaTokens.poloBlue22),
                  ),
                  child: Column(
                    children: [
                      _MetricRow(
                        label: 'Total Transactions:',
                        value: '$totalCount entries',
                      ),
                      const SizedBox(height: 8),
                      _MetricRow(label: 'Date Coverage:', value: dateRangeStr),
                      const SizedBox(height: 8),
                      _MetricRow(
                        label: 'CSV Schema:',
                        value: 'RFC 4180 (8 Columns)',
                        valueColor: KasyabaTokens.casablanca,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: 'Save CSV File to Device',
                  icon: Icons.file_download_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : () => _saveCsv(csvContent),
                ),
                const SizedBox(height: 10),
                PillButton(
                  label: 'Copy CSV to Clipboard',
                  icon: Icons.copy_rounded,
                  variant: PillButtonVariant.secondary,
                  onPressed: () => _copyCsv(csvContent),
                ),
              ],
            ],
          ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String badge;
  final String subtitle;

  const _SheetHeader({
    required this.icon,
    required this.accent,
    required this.title,
    required this.badge,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Icon(icon, color: accent, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.dmSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: KasyabaTokens.periwinkleGraySubtitle,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 20),
          color: KasyabaTokens.periwinkleGraySubtitle,
        ),
      ],
    );
  }
}

class _ValidationCard extends StatelessWidget {
  final Color background;
  final Color border;
  final IconData icon;
  final Color iconColor;
  final String? title;
  final Color titleColor;
  final String message;
  final Color messageColor;

  const _ValidationCard({
    required this.background,
    required this.border,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    required this.message,
    required this.messageColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title!,
                    style: GoogleFonts.dmSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: messageColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _MetricRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: KasyabaTokens.periwinkleGraySubtitle,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: CurrencyFormatter.tabularFigures,
              color: valueColor ?? KasyabaTokens.periwinkleGray,
            ),
          ),
        ),
      ],
    );
  }
}

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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        '$count $label',
        style: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFeatures: CurrencyFormatter.tabularFigures,
          color: color,
        ),
      ),
    );
  }
}
