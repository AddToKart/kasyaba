import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/offline/offline_capabilities.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/validated_input.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/kasyaba_date_picker.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isFutureDate(DateTime date) =>
    _dateOnly(date).isAfter(_dateOnly(DateTime.now()));

String _categoryKey(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _categoryNamesMatch(String left, String right) {
  final a = _categoryKey(left);
  final b = _categoryKey(right);
  return a == b || a.startsWith(b) || b.startsWith(a);
}

enum TransactionTypeMode { expense, income, transfer }

/// ─────────────────────────────────────────────────────────────
///  Add Transaction / Transfer Screen
///  Figma 1:1 Carbon Copy:
///    - Node 37:6387 (Add Expense)
///    - Node 37:6390 (Add Income)
///    - Node 42:6422 (Transfer Cash)
/// ─────────────────────────────────────────────────────────────
class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionEntry? transaction;
  final String? initialType;

  const AddTransactionScreen({super.key, this.transaction, this.initialType});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _feeController = TextEditingController(text: '');

  TransactionTypeMode _mode = TransactionTypeMode.expense;
  bool get _isExpense => _mode == TransactionTypeMode.expense;
  bool get _isIncome => _mode == TransactionTypeMode.income;
  bool get _isTransfer => _mode == TransactionTypeMode.transfer;

  bool _isSubmitting = false;
  String? _selectedCategory;
  String? _selectedCategoryName;
  String? _selectedAccount;
  String? _selectedToAccount;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  String _selectedFeePreset = 'Free';
  String _selectedIncomeSource = 'Salary';

  static const List<String> _incomeSources = [
    'Salary',
    'Freelance',
    'Allowance',
    'Other',
  ];

  static const List<Map<String, dynamic>> _transferFeePresets = [
    {'label': 'Free', 'amount': 0.0},
    {'label': '₱10', 'amount': 10.0},
    {'label': '₱15 InstaPay', 'amount': 15.0},
    {'label': '₱25', 'amount': 25.0},
  ];

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    if (transaction != null) {
      if (transaction.isTransfer) {
        _mode = TransactionTypeMode.transfer;
      } else if (transaction.isExpense) {
        _mode = TransactionTypeMode.expense;
      } else {
        _mode = TransactionTypeMode.income;
      }
    } else {
      final initial = widget.initialType?.toLowerCase();
      if (initial == 'income') {
        _mode = TransactionTypeMode.income;
      } else if (initial == 'transfer') {
        _mode = TransactionTypeMode.transfer;
      } else {
        _mode = TransactionTypeMode.expense;
      }
    }

    _selectedCategory = transaction?.categoryId ?? 'cat_food';
    _selectedCategoryName = transaction?.categoryName ?? 'Food & Dining';
    _selectedAccount = transaction?.accountId;
    _selectedDate = transaction?.date ?? _dateOnly(DateTime.now());

    if (transaction != null) {
      _amountController.text =
          transaction.amount == transaction.amount.roundToDouble()
          ? transaction.amount.toInt().toString()
          : transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.title;
      _notesController.text = transaction.notes ?? '';
    }

    _amountController.addListener(_onStateChange);
    _descriptionController.addListener(_onStateChange);
    _feeController.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onStateChange);
    _descriptionController.removeListener(_onStateChange);
    _feeController.removeListener(_onStateChange);
    _amountController.dispose();
    _descriptionController.dispose();
    _feeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/transactions');
    }
  }

  void _switchMode(TransactionTypeMode targetMode) {
    if (_mode == targetMode) return;
    AppHaptics.selectionClick();
    setState(() {
      _mode = targetMode;
    });
  }

  String _formatDateDisplay(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    final formatted = DateFormat('MMM d').format(date);
    return isToday
        ? 'Today, $formatted'
        : DateFormat('EEE, MMM d').format(date);
  }

  Future<void> _selectDate() async {
    AppHaptics.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100, 12, 31),
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(data: kasyabaDatePickerTheme(ctx), child: child);
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = _dateOnly(picked));
    }
  }

  Future<void> _showAccountPicker({required bool isDestination}) async {
    AppHaptics.selectionClick();
    final accounts = ref.read(accountsProvider).valueOrNull ?? [];
    final balances = ref.read(accountBalancesProvider).valueOrNull ?? {};

    if (accounts.isEmpty) {
      KasyabaToast.showError(
        context,
        'No accounts available',
        subtitle: 'Create one in Accounts first.',
      );
      return;
    }

    await showKasyabaSheet<String>(
      context: context,
      builder: (sheetContext) {
        return AppSheet(
          color: DashboardTokens.bigStone,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDestination
                      ? 'Select Destination Account'
                      : 'Select Account',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: DashboardTokens.poloBlue16),
                    itemBuilder: (ctx, idx) {
                      final acc = accounts[idx];
                      final bal = balances[acc.id] ?? 0.0;
                      final isSelected = isDestination
                          ? _selectedToAccount == acc.id
                          : _selectedAccount == acc.id;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        title: Text(
                          acc.name,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected
                                ? DashboardTokens.bermuda
                                : DashboardTokens.periwinkleGray,
                          ),
                        ),
                        subtitle: Text(
                          acc.type.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(bal),
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop(acc.id);
                        },
                      );
                    },
              ),
            ],
          ),
        ),
        );
      },
    ).then((chosenId) {
      if (chosenId != null && mounted) {
        setState(() {
          if (isDestination) {
            _selectedToAccount = chosenId;
          } else {
            _selectedAccount = chosenId;
          }
        });
      }
    });
  }

  void _swapAccounts() {
    AppHaptics.mediumImpact();
    setState(() {
      final temp = _selectedAccount;
      _selectedAccount = _selectedToAccount;
      _selectedToAccount = temp;
    });
  }

  String? _effectiveAccountId(List<Account> accounts) =>
      _selectedAccount ??
      widget.transaction?.accountId ??
      (accounts.isNotEmpty ? accounts.first.id : null);

  String? _effectiveToAccountId(List<Account> accounts, String? fromAccountId) {
    if (_selectedToAccount != null) return _selectedToAccount;
    if (accounts.length < 2) return null;
    return accounts
        .firstWhere(
          (account) => account.id != fromAccountId,
          orElse: () => accounts.last,
        )
        .id;
  }

  String get _incomeSourceValue {
    final description = _descriptionController.text.trim();
    return description.isNotEmpty ? description : _selectedIncomeSource;
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;
    if (widget.transaction != null && !ref.read(isOnlineProvider)) {
      KasyabaToast.showInfo(
        context,
        'Editing a transaction needs an internet connection.',
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final accounts = ref.read(accountsProvider).valueOrNull ?? [];

    if (_isTransfer) {
      final fromAccountId = _effectiveAccountId(accounts);
      final toAccountId = _effectiveToAccountId(accounts, fromAccountId);
      if (fromAccountId == null ||
          !RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
          ).hasMatch(fromAccountId)) {
        KasyabaToast.showError(context, 'Select a valid source wallet.');
        return;
      }
      if (toAccountId == null ||
          !RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
          ).hasMatch(toAccountId)) {
        KasyabaToast.showError(context, 'Select a valid destination wallet.');
        return;
      }
      if (fromAccountId == toAccountId) {
        KasyabaToast.showError(
          context,
          'Source and destination wallets must be different.',
        );
        return;
      }

      final amount =
          double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
          0.0;
      if (amount <= 0) {
        KasyabaToast.showError(context, 'Enter an amount greater than zero.');
        return;
      }

      final fee =
          double.tryParse(_feeController.text.replaceAll(',', '').trim()) ??
          0.0;
      if (fee < 0) {
        KasyabaToast.showError(context, 'Transfer fee cannot be negative.');
        return;
      }

      setState(() => _isSubmitting = true);
      final description = _descriptionController.text.trim();
      final notes = _notesController.text.trim();

      try {
        final mutator = ref.read(transactionMutatorProvider);
        final fromAcc = accounts.firstWhere(
          (a) => a.id == fromAccountId,
          orElse: () => Account(id: fromAccountId, name: 'Source Wallet'),
        );
        final toAcc = accounts.firstWhere(
          (a) => a.id == toAccountId,
          orElse: () => Account(id: toAccountId, name: 'Destination Wallet'),
        );

        final transferNote = notes.isNotEmpty
            ? notes
            : (description.isNotEmpty
                  ? description
                  : 'Transfer: ${fromAcc.name} → ${toAcc.name}');

        final saveStatus = await mutator.addTransfer(
          fromAccountId: fromAccountId,
          toAccountId: toAccountId,
          amount: amount,
          transferredAt: _selectedDate,
          notes: transferNote,
        );

        if (fee > 0) {
          await mutator.addExpense(
            accountId: fromAccountId,
            categoryId: 'cat_other',
            categoryName: 'Bank & Transfer Fees',
            amount: fee,
            description: 'Transfer Fee (${fromAcc.name} → ${toAcc.name})',
            spentAt: _selectedDate,
            notes:
                'Automated transfer fee for transfer of ${CurrencyFormatter.format(amount)}',
          );
        }

        if (mounted) {
          final transferMsg = saveStatus == TransactionSaveStatus.queued
              ? 'Transfer saved offline'
              : 'Transfer recorded!';
          final transferSubtitle = saveStatus == TransactionSaveStatus.queued
              ? 'Will sync when online'
              : (fee > 0
                    ? '${CurrencyFormatter.format(amount)} + ${CurrencyFormatter.format(fee)} fee'
                    : CurrencyFormatter.format(amount));

          KasyabaToast.showSuccess(
            context,
            transferMsg,
            subtitle: transferSubtitle,
          );
          _handleClose();
        }
      } catch (e) {
        if (mounted) {
          KasyabaToast.showError(
            context,
            friendlyErrorMessage(
              e,
              fallback: 'Could not record transfer. Please try again.',
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
      return;
    }

    final accountId = _effectiveAccountId(accounts);
    if (accountId == null ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(accountId)) {
      KasyabaToast.showError(context, 'Select an available account first.');
      return;
    }

    var categoryIdToUse = _selectedCategory ?? 'cat_food';
    final serverCategories = ref.read(categoriesProvider).valueOrNull ?? [];
    final selectedCategoryName = _selectedCategoryName;
    final hasServerCategory = serverCategories.any(
      (category) => category.id == categoryIdToUse,
    );
    if (!hasServerCategory && selectedCategoryName != null) {
      for (final category in serverCategories) {
        if (_categoryNamesMatch(selectedCategoryName, category.name)) {
          categoryIdToUse = category.id;
          break;
        }
      }
    }

    final isExpense = _isExpense;
    setState(() => _isSubmitting = true);

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();
    final incomeSource = _incomeSourceValue;
    final isScheduled = _isFutureDate(_selectedDate);

    try {
      final mutator = ref.read(transactionMutatorProvider);
      TransactionSaveStatus? saveStatus;
      final existing = widget.transaction;
      if (existing != null) {
        if (isExpense) {
          await mutator.updateExpense(
            id: existing.id,
            accountId: accountId,
            categoryId: categoryIdToUse,
            amount: amount,
            description: description.isNotEmpty ? description : 'Expense',
            spentAt: _selectedDate,
            notes: notes,
          );
        } else {
          await mutator.updateIncome(
            id: existing.id,
            accountId: accountId,
            amount: amount,
            source: incomeSource,
            receivedAt: _selectedDate,
            notes: notes,
          );
        }
      } else if (isExpense) {
        saveStatus = await mutator.addExpense(
          accountId: accountId,
          categoryId: categoryIdToUse,
          categoryName: _selectedCategoryName,
          amount: amount,
          description: description.isNotEmpty ? description : 'Expense',
          spentAt: _selectedDate,
          notes: notes,
        );
      } else {
        saveStatus = await mutator.addIncome(
          accountId: accountId,
          amount: amount,
          source: incomeSource,
          receivedAt: _selectedDate,
          notes: notes,
        );
      }

      if (mounted) {
        final label = isExpense ? 'Expense' : 'Income';
        final message = saveStatus == TransactionSaveStatus.queued
            ? '$label saved offline'
            : existing != null
            ? '$label updated'
            : isScheduled
            ? '$label scheduled'
            : '$label recorded!';
        final subtitle = saveStatus == TransactionSaveStatus.queued
            ? 'Will sync automatically when online'
            : CurrencyFormatter.format(amount);

        if (isExpense) {
          KasyabaToast.showInfo(
            context,
            message,
            subtitle: subtitle,
            icon: Icons.receipt_long_rounded,
            accentColor: DashboardTokens.apricot,
          );
        } else {
          KasyabaToast.showSuccess(context, message, subtitle: subtitle);
        }
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            e,
            fallback:
                'Could not save ${isExpense ? "expense" : "income"}. Please try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isOnline = ref.watch(isOnlineProvider);
    final isEditing = widget.transaction != null;
    final queueableAction = switch (_mode) {
      TransactionTypeMode.expense => OfflineAction.addExpense,
      TransactionTypeMode.income => OfflineAction.addIncome,
      TransactionTypeMode.transfer => OfflineAction.addTransfer,
    };
    final accounts = ref.watch(accountsProvider).valueOrNull ?? [];
    final balances = ref.watch(accountBalancesProvider).valueOrNull ?? {};

    final effectiveAccountId = _effectiveAccountId(accounts);
    final effectiveToAccountId = _effectiveToAccountId(
      accounts,
      effectiveAccountId,
    );

    final currentAccount = accounts
        .where((account) => account.id == effectiveAccountId)
        .firstOrNull;
    final currentToAccount = accounts
        .where((account) => account.id == effectiveToAccountId)
        .firstOrNull;

    final currentAccountBalance = currentAccount == null
        ? 0.0
        : balances[currentAccount.id] ?? 0.0;
    final toAccountBalance = currentToAccount == null
        ? 0.0
        : balances[currentToAccount.id] ?? 0.0;

    final displayAccount = currentAccount ?? const Account(id: '', name: '—');
    final displayToAccount =
        currentToAccount ?? const Account(id: '', name: '—');

    final fetchedCategories = ref.watch(categoriesProvider).valueOrNull;
    final categories = (fetchedCategories == null || fetchedCategories.isEmpty)
        ? defaultCategoriesList
        : fetchedCategories;
    final quickCategories = categories.take(6).toList();

    final inputAmount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;

    // Balance calculations for hero preview
    final double afterBalance;
    if (_isExpense) {
      afterBalance = currentAccountBalance - inputAmount;
    } else if (_isIncome) {
      afterBalance = currentAccountBalance + inputAmount;
    } else {
      afterBalance = currentAccountBalance - inputAmount;
    }

    // Title based on mode and edit status
    final String pageTitle;
    if (widget.transaction != null) {
      pageTitle = _isExpense
          ? 'Edit Expense'
          : (_isIncome ? 'Edit Income' : 'Edit Transfer');
    } else {
      pageTitle = _isExpense
          ? 'Add Expense'
          : (_isIncome ? 'Add Income' : 'Transfer Cash');
    }

    final String buttonLabel;
    if (widget.transaction != null) {
      buttonLabel =
          'Update ${_isExpense ? "expense" : (_isIncome ? "income" : "transfer")}';
    } else {
      buttonLabel = _isExpense
          ? 'Save expense'
          : (_isIncome ? 'Save income' : 'Save transfer');
    }

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
            padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, DashboardTokens.dockClearance),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Header Row (Back Button + Title) ───────────────
                  Row(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          AppHaptics.selectionClick();
                          _handleClose();
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
                          pageTitle,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: DashboardTokens.periwinkleGray,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── 3-Way Mode Switcher (Node 11:2372) ───────────────────
                  SlidingSegmentedPill(
                    height: 54,
                    pillRadius: 26,
                    borderRadius: 30,
                    fontSize: 15,
                    items: const ['Expense', 'Income', 'Transfer'],
                    selectedIndex: _mode.index,
                    onChanged: (idx) =>
                        _switchMode(TransactionTypeMode.values[idx]),
                  ),
                  const SizedBox(height: 14),

                  // ── Hero Amount Card (Node 11:2379) ──────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 19,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: DashboardTokens.cello60,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: DashboardTokens.poloBlue30,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Currency symbol & Large Amount Input
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '₱',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGraySubtitle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: IntrinsicWidth(
                                child: TextFormField(
                                  controller: _amountController,
                                  inputFormatters: [
                                    currencyAmountInputFormatter,
                                  ],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 46,
                                    fontWeight: FontWeight.bold,
                                    color: DashboardTokens.periwinkleGray,
                                    height: 1.1,
                                  ),
                                  textAlign: TextAlign.left,
                                  cursorColor: DashboardTokens.periwinkleGray,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: GoogleFonts.bricolageGrotesque(
                                      fontSize: 46,
                                      fontWeight: FontWeight.bold,
                                      color: DashboardTokens.periwinkleGray
                                          .withValues(alpha: 0.35),
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  validator: (value) {
                                    final val = double.tryParse(
                                      value?.replaceAll(',', '').trim() ?? '',
                                    );
                                    if (val == null || val <= 0) {
                                      return 'Enter valid amount';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Balance Preview Subtitle — suppressed until a real
                        // wallet exists so it never shows fabricated values.
                        if (accounts.isEmpty)
                          Text(
                            'Add a wallet to track its balance live',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                          )
                        else
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: DashboardTokens.periwinkleGraySubtitle,
                              ),
                              children: [
                                TextSpan(
                                  text: _isTransfer
                                      ? '${displayAccount.name}: ${CurrencyFormatter.format(currentAccountBalance)} → '
                                      : 'Balance after: ${CurrencyFormatter.format(currentAccountBalance)} → ',
                                ),
                                TextSpan(
                                  text: CurrencyFormatter.format(afterBalance),
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
                  ),
                  const SizedBox(height: 14),

                  // ── Mode-Specific Body ────────────────────────────────────
                  if (_isExpense) ...[
                    _buildExpenseBody(
                      displayAccount,
                      currentAccountBalance,
                      quickCategories,
                    ),
                  ] else if (_isIncome) ...[
                    _buildIncomeBody(displayAccount, currentAccountBalance),
                  ] else ...[
                    _buildTransferBody(
                      displayAccount,
                      currentAccountBalance,
                      displayToAccount,
                      toAccountBalance,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Offline capability note ───────────────────────────────
                  if (!isOnline) ...[
                    if (isEditing)
                      const NeedsInternetNotice(
                        message:
                            'Editing a transaction needs an internet connection.',
                      )
                    else if (OfflineCapabilities.isQueueable(queueableAction))
                      const OfflineQueuedNote(),
                    const SizedBox(height: 12),
                  ],

                  // ── CTA Button ────────────────────────────────────────────
                  PillButton(
                    label: buttonLabel,
                    onPressed: _isSubmitting || (isEditing && !isOnline)
                        ? null
                        : _handleSave,
                    isLoading: _isSubmitting,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Expense Body (Node 37:6387) ───────────────────────────────────────────
  Widget _buildExpenseBody(
    Account account,
    double balance,
    List<Category> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Note Card
        _buildInputRowCard(
          label: 'Note',
          child: TextFormField(
            controller: _descriptionController,
            maxLength: kMaxDescriptionLength,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTokens.periwinkleGray,
            ),
            cursorColor: DashboardTokens.periwinkleGray,
            decoration: InputDecoration(
              hintText: 'e.g. Grocery shopping',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray.withValues(alpha: 0.4),
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
        const SizedBox(height: 14),

        // CATEGORY Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CATEGORY',
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
              children: [
                ...categories.map((cat) {
                  final isSelected =
                      _selectedCategoryName == cat.name ||
                      _selectedCategory == cat.id;
                  return _buildCategoryChip(
                    label: cat.name,
                    isSelected: isSelected,
                    onTap: () {
                      AppHaptics.selectionClick();
                      setState(() {
                        _selectedCategory = cat.id;
                        _selectedCategoryName = cat.name;
                      });
                    },
                  );
                }),
                _buildCategoryChip(
                  label: 'More',
                  isSelected: false,
                  onTap: _showAllCategoriesSheet,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Account Card
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showAccountPicker(isDestination: false),
          child: _buildInputRowCard(
            label: 'Account',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    account.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
                Text(
                  _accountBalanceLabel(account, balance),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Date Card
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _selectDate,
          child: _buildInputRowCard(
            label: 'Date',
            child: Text(
              _formatDateDisplay(_selectedDate),
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Income Body (Node 37:6390) ────────────────────────────────────────────
  Widget _buildIncomeBody(Account account, double balance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SOURCE Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SOURCE',
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
              children: _incomeSources.map((source) {
                return _buildCategoryChip(
                  label: source,
                  isSelected: _selectedIncomeSource == source,
                  onTap: () {
                    AppHaptics.selectionClick();
                    final current = _descriptionController.text.trim();
                    final isPreset =
                        current.isEmpty || _incomeSources.contains(current);
                    setState(() {
                      _selectedIncomeSource = source;
                      if (isPreset) {
                        _descriptionController.text = source;
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Note Card
        _buildInputRowCard(
          label: 'Note',
          child: TextFormField(
            controller: _descriptionController,
            maxLength: kMaxDescriptionLength,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTokens.periwinkleGray,
            ),
            cursorColor: DashboardTokens.periwinkleGray,
            decoration: InputDecoration(
              hintText: 'e.g. Salary payout',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray.withValues(alpha: 0.4),
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
        const SizedBox(height: 14),

        // Account Card
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showAccountPicker(isDestination: false),
          child: _buildInputRowCard(
            label: 'Account',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    account.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
                Text(
                  _accountBalanceLabel(account, balance),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Date Card
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _selectDate,
          child: _buildInputRowCard(
            label: 'Date',
            child: Text(
              _formatDateDisplay(_selectedDate),
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Optional Notes Card
        _buildInputRowCard(
          label: 'Notes',
          child: TextFormField(
            controller: _notesController,
            maxLength: kMaxNotesLength,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTokens.periwinkleGray,
            ),
            cursorColor: DashboardTokens.periwinkleGray,
            decoration: InputDecoration(
              hintText: 'Optional',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray.withValues(alpha: 0.4),
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
      ],
    );
  }

  // ── Transfer Body (Node 42:6422) ──────────────────────────────────────────
  Widget _buildTransferBody(
    Account fromAccount,
    double fromBalance,
    Account toAccount,
    double toBalance,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // From Account Card
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showAccountPicker(isDestination: false),
          child: _buildInputRowCard(
            label: 'From',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fromAccount.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
                Text(
                  _accountBalanceLabel(fromAccount, fromBalance),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Swap Button (Node 11:2269)
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _swapAccounts,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: DashboardTokens.kashmirBlue,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/images/transfer_swap.svg',
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      DashboardTokens.periwinkleGray,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Swap',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // To Account Card
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showAccountPicker(isDestination: true),
          child: _buildInputRowCard(
            label: 'To',
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    toAccount.name,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
                Text(
                  _accountBalanceLabel(toAccount, toBalance),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // TRANSFER FEE Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRANSFER FEE',
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
              children: _transferFeePresets.map((preset) {
                final isSelected = _selectedFeePreset == preset['label'];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() {
                      _selectedFeePreset = preset['label'] as String;
                      final amt = preset['amount'] as double;
                      _feeController.text = amt > 0
                          ? amt.toStringAsFixed(2)
                          : '';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? DashboardTokens.periwinkleGray
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: DashboardTokens.poloBlue.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                            ),
                    ),
                    child: Text(
                      preset['label'] as String,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? DashboardTokens.ebony
                            : DashboardTokens.periwinkleGray,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Note Card
        _buildInputRowCard(
          label: 'Note',
          child: TextFormField(
            controller: _notesController,
            maxLength: kMaxNotesLength,
            buildCounter: (
              context, {
              required currentLength,
              required isFocused,
              maxLength,
            }) => null,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardTokens.periwinkleGray,
            ),
            cursorColor: DashboardTokens.periwinkleGray,
            decoration: InputDecoration(
              hintText: 'Optional',
              hintStyle: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: DashboardTokens.periwinkleGray.withValues(alpha: 0.4),
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
        const SizedBox(height: 8),

        // Helper text below Note
        Text(
          'From and To must be different accounts.',
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: DashboardTokens.periwinkleGraySubtitle,
          ),
        ),
      ],
    );
  }

  String _accountBalanceLabel(Account account, double balance) =>
      account.id.isEmpty ? '—' : CurrencyFormatter.format(balance);

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? DashboardTokens.periwinkleGray
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? null
              : Border.all(
                  color: DashboardTokens.poloBlue.withValues(alpha: 0.4),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected
                ? DashboardTokens.ebony
                : DashboardTokens.periwinkleGray,
          ),
        ),
      ),
    );
  }

  // ── Helper Row Card (height 58, big stone fill, polo blue 22% border) ─────
  Widget _buildInputRowCard({required String label, required Widget child}) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: DashboardTokens.periwinkleGraySubtitle,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _showAllCategoriesSheet() {
    AppHaptics.selectionClick();
    final fetched = ref.read(categoriesProvider).valueOrNull;
    final categories = (fetched == null || fetched.isEmpty)
        ? defaultCategoriesList
        : fetched;
    showKasyabaSheet<Category>(
      context: context,
      builder: (sheetContext) {
        return AppSheet(
          color: DashboardTokens.bigStone,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Category',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: DashboardTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                itemCount: categories.length,
                separatorBuilder: (_, _) =>
                    Divider(height: 1, color: DashboardTokens.poloBlue16),
                itemBuilder: (ctx, idx) {
                  final c = categories[idx];
                  return ListTile(
                    title: Text(
                      c.name,
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    onTap: () => Navigator.of(sheetContext).pop(c),
                  );
                },
              ),
            ],
          ),
        ),
        );
      },
    ).then((cat) {
      if (cat != null && mounted) {
        setState(() {
          _selectedCategory = cat.id;
          _selectedCategoryName = cat.name;
        });
      }
    });
  }
}
