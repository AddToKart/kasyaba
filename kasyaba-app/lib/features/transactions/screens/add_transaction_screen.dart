import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../core/utils/currency_formatter.dart';

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

class AddTransactionScreen extends ConsumerStatefulWidget {
  final TransactionEntry? transaction;
  final String? initialType;

  const AddTransactionScreen({super.key, this.transaction, this.initialType});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isExpense = true;
  bool _isSubmitting = false;
  String? _selectedCategory;
  String? _selectedAccount;
  DateTime _selectedDate = _dateOnly(DateTime.now());
  String? _selectedCategoryName;

  late final AnimationController _typeController;

  final List<Map<String, String>> _categoryItems = [
    {'id': 'cat_food', 'name': 'Food & Dining'},
    {'id': 'cat_transport', 'name': 'Transportation'},
    {'id': 'cat_utilities', 'name': 'Utilities & Bills'},
    {'id': 'cat_rent', 'name': 'Rent & Housing'},
    {'id': 'cat_education', 'name': 'Education'},
    {'id': 'cat_healthcare', 'name': 'Healthcare'},
    {'id': 'cat_entertainment', 'name': 'Entertainment'},
    {'id': 'cat_shopping', 'name': 'Shopping'},
    {'id': 'cat_other', 'name': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    // Initial type only applies to new entries; edits keep the stored type.
    _isExpense =
        transaction?.isExpense ??
        (widget.initialType?.toLowerCase() == 'income' ? false : true);
    _selectedCategory = transaction?.categoryId ?? _categoryItems.first['id'];
    _selectedCategoryName =
        transaction?.categoryName ?? _categoryItems.first['name'];
    _selectedAccount = transaction?.accountId;
    _selectedDate = transaction?.date ?? _dateOnly(DateTime.now());
    if (transaction != null) {
      _amountController.text = transaction.amount.toStringAsFixed(2);
      _descriptionController.text = transaction.title;
      _notesController.text = transaction.notes ?? '';
    }
    _amountController.addListener(_onAmountChanged);
    _descriptionController.addListener(_onDescriptionChanged);
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _typeController.forward();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  void _onDescriptionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _typeController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  void _switchType(bool toExpense) {
    if (_isExpense == toExpense) return;
    _typeController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _isExpense = toExpense);
      _typeController.forward();
    });
  }

  String? _selectedCategoryForDisplay(List<Map<String, String>> categories) {
    if (_selectedCategory != null &&
        categories.any((category) => category['id'] == _selectedCategory)) {
      return _selectedCategory;
    }

    final selectedName = _selectedCategoryName;
    if (selectedName != null) {
      for (final category in categories) {
        final name = category['name'];
        if (name != null && _categoryNamesMatch(selectedName, name)) {
          return category['id'];
        }
      }
    }

    return categories.isNotEmpty ? categories.first['id'] : _selectedCategory;
  }

  String _successMessage({
    required bool isExpense,
    required bool isScheduled,
    TransactionSaveStatus? status,
  }) {
    final label = isExpense ? 'Expense' : 'Income';
    if (status == TransactionSaveStatus.queued) {
      return '$label saved offline — will sync when online';
    }
    if (widget.transaction != null) return '$label updated';
    if (isScheduled) return '$label scheduled';
    return '$label recorded!';
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      // Transactions can be entered before they happen. They are treated as
      // scheduled until their date arrives.
      lastDate: DateTime(2100, 12, 31),
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(
          data: Theme.of(ctx).copyWith(colorScheme: Theme.of(ctx).colorScheme),
          child: child,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => _selectedDate = _dateOnly(picked));
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final accountId = _selectedAccount ?? widget.transaction?.accountId;
    if (accountId == null ||
        !RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(accountId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an available account first.')),
      );
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

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();
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
            description: description,
            spentAt: _selectedDate,
            notes: notes,
          );
        } else {
          await mutator.updateIncome(
            id: existing.id,
            accountId: accountId,
            amount: amount,
            source: description,
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
          description: description,
          spentAt: _selectedDate,
          notes: notes,
        );
      } else {
        saveStatus = await mutator.addIncome(
          accountId: accountId,
          amount: amount,
          source: description,
          receivedAt: _selectedDate,
          notes: notes,
        );
      }

      if (mounted) {
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
                Text(
                  _successMessage(
                    isExpense: isExpense,
                    isScheduled: isScheduled,
                    status: saveStatus,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: isExpense ? AppColors.expense : AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                e,
                fallback:
                    'Could not save ${isExpense ? "expense" : "income"}. Please try again.',
              ),
            ),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final rawCategories = categoriesAsync.maybeWhen(
      data: (cats) => cats.isNotEmpty
          ? cats
                .map((c) => {'id': c.id, 'name': c.name})
                .toList()
          : _categoryItems,
      orElse: () => _categoryItems,
    );

    // Ensure 'Other' category is always sorted to the last position
    final availableCategories = <Map<String, String>>[];
    Map<String, String>? otherCategory;
    for (final cat in rawCategories) {
      if ((cat['name'] ?? '').toLowerCase().contains('other')) {
        otherCategory = cat;
      } else {
        availableCategories.add(cat);
      }
    }
    if (otherCategory != null) {
      availableCategories.add(otherCategory);
    }

    final selectedCategoryId = _selectedCategoryForDisplay(availableCategories);

    // Compute live deterministic current balance & projected balance
    final accountBalances =
        ref.watch(accountBalancesProvider).valueOrNull ?? const {};
    final defaultBalance =
        ref.watch(dashboardProvider).valueOrNull?.totalBalance ?? 0.0;
    final currentBalance =
        accountBalances[_selectedAccount] ?? defaultBalance;
    final parsedAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final projectedBalance = _isExpense
        ? (currentBalance - parsedAmount)
        : (currentBalance + parsedAmount);

    // Determine accent color based on type
    final typeColor = _isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor: isDark ? AppColors.obsidian : AppColors.lightBg,

      // ── App Bar ─────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isDark
                  ? AppColors.surface700.withValues(alpha: 0.7)
                  : AppColors.lightCard,
              border: Border.all(
                color: isDark ? AppColors.surface600 : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            ),
          ),
          onPressed: _handleClose,
          tooltip: 'Close',
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            widget.transaction == null
                ? (_isExpense ? 'Add Expense' : 'Add Income')
                : (_isExpense ? 'Edit Expense' : 'Edit Income'),
            key: ValueKey(_isExpense),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
              color: isDark ? Colors.white : AppColors.textLight,
            ),
          ),
        ),
        centerTitle: true,
      ),

      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Type cannot be changed while editing because that would
                // turn one database record into a different resource type.
                if (widget.transaction == null)
                  _TypeSwitcher(
                    isExpense: _isExpense,
                    isDark: isDark,
                    onExpense: () => _switchType(true),
                    onIncome: () => _switchType(false),
                  )
                else
                  _TransactionTypeBadge(isExpense: _isExpense, isDark: isDark),
                const SizedBox(height: 16),

                // ── Amount Card ──────────────────────────
                _AmountCard(
                  controller: _amountController,
                  isExpense: _isExpense,
                  isDark: isDark,
                  typeColor: typeColor,
                  currentBalance: currentBalance,
                  projectedBalance: projectedBalance,
                ),
                const SizedBox(height: 16),

                // ── Details Card ─────────────────────────
                ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description or Income Source
                      _FieldLabel(
                        label: _isExpense ? 'Description' : 'Income Source',
                        isDark: isDark,
                      ),
                      if (!_isExpense) ...[
                        const SizedBox(height: 8),
                        _IncomeQuickPresets(
                          selectedSource: _descriptionController.text.trim(),
                          isDark: isDark,
                          onSelect: (preset) {
                            setState(() {
                              _descriptionController.text = preset;
                            });
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: _isExpense
                              ? 'e.g. Grocery Shopping, Electricity Bill'
                              : 'e.g. Monthly Salary, Freelance Work',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.description_outlined, size: 20),
                          ),
                        ),
                        validator: (v) => (v?.trim().length ?? 0) >= 1
                            ? null
                            : 'Description is required',
                      ),
                      const SizedBox(height: 20),

                      // Category (expense only)
                      if (_isExpense) ...[
                        _FieldLabel(label: 'Category', isDark: isDark),
                        const SizedBox(height: 10),
                        _CategoryGrid(
                          categories: availableCategories,
                          selectedId: selectedCategoryId,
                          isDark: isDark,
                          onSelect: (id) {
                            final selected = availableCategories.firstWhere(
                              (category) => category['id'] == id,
                            );
                            setState(() {
                              _selectedCategory = id;
                              _selectedCategoryName = selected['name'];
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Account / Wallet
                      _FieldLabel(label: 'Account / Wallet', isDark: isDark),
                      const SizedBox(height: 8),
                      accountsAsync.when(
                        loading: () => const LinearProgressIndicator(
                          color: AppColors.emerald500,
                        ),
                        error: (_, _) => InkWell(
                          onTap: () => ref.invalidate(accountsProvider),
                          borderRadius:
                              BorderRadius.circular(AppTheme.inputRadius),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surface700.withValues(alpha: 0.5)
                                  : AppColors.lightCard2,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.inputRadius),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.surface600
                                        .withValues(alpha: 0.7)
                                    : AppColors.lightBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.refresh_rounded,
                                  size: 18,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Retry loading wallets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textDark
                                        : AppColors.textLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        data: (accounts) {
                          if (accounts.isEmpty) {
                            return _NoAccountsNotice(isDark: isDark);
                          }
                          if (_selectedAccount == null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && _selectedAccount == null) {
                                setState(
                                  () => _selectedAccount = accounts.first.id,
                                );
                              }
                            });
                          }
                          return _AccountDropdown(
                            accounts: accounts,
                            selectedAccountId: _selectedAccount,
                            accountBalances: accountBalances,
                            defaultBalance: defaultBalance,
                            isDark: isDark,
                            onChanged: (id) =>
                                setState(() => _selectedAccount = id),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date
                      _FieldLabel(label: 'Transaction Date', isDark: isDark),
                      const SizedBox(height: 8),
                      _DatePicker(
                        selectedDate: _selectedDate,
                        isDark: isDark,
                        onTap: _selectDate,
                      ),
                      if (_isFutureDate(_selectedDate)) ...[
                        const SizedBox(height: 10),
                        _ScheduledDateNotice(
                          isExpense: _isExpense,
                          selectedDate: _selectedDate,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Notes (Optional)
                      _FieldLabel(label: 'Notes (Optional)', isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        textAlignVertical: TextAlignVertical.top,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add optional note or reference...',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedL,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIconConstraints: const BoxConstraints(
                            minWidth: 40,
                            maxHeight: 60,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, top: 12),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textMutedL,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),

      // ── Sticky Bottom Action Bar ──────────────────────────
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.obsidian : AppColors.lightBg)
                  .withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color:
                      isDark ? AppColors.subtleBorder : AppColors.lightBorder,
                  width: 1,
                ),
              ),
            ),
            child: _SaveButton(
              isExpense: _isExpense,
              isEditing: widget.transaction != null,
              isSubmitting: _isSubmitting,
              onPressed: _handleSave,
              typeColor: typeColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Type Switcher ────────────────────────────────────────────

class _TypeSwitcher extends StatelessWidget {
  final bool isExpense;
  final bool isDark;
  final VoidCallback onExpense;
  final VoidCallback onIncome;

  const _TypeSwitcher({
    required this.isExpense,
    required this.isDark,
    required this.onExpense,
    required this.onIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface700 : AppColors.lightCard2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.surface600 : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          _TypeTab(
            label: 'Expense',
            icon: Icons.arrow_upward_rounded,
            isSelected: isExpense,
            activeColor: AppColors.expense,
            isDark: isDark,
            onTap: onExpense,
          ),
          _TypeTab(
            label: 'Income',
            icon: Icons.arrow_downward_rounded,
            isSelected: !isExpense,
            activeColor: AppColors.income,
            isDark: isDark,
            onTap: onIncome,
          ),
        ],
      ),
    );
  }
}

class _TransactionTypeBadge extends StatelessWidget {
  final bool isExpense;
  final bool isDark;

  const _TransactionTypeBadge({required this.isExpense, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isExpense
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 8),
          Text(
            isExpense ? 'Expense' : 'Income',
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.textLight,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _TypeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        onTap: onTap,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textMuted : AppColors.textMutedL),
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppColors.textMuted : AppColors.textMutedL),
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

// ─── Amount Card ──────────────────────────────────────────────

class _AmountCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpense;
  final bool isDark;
  final Color typeColor;
  final double currentBalance;
  final double projectedBalance;

  const _AmountCard({
    required this.controller,
    required this.isExpense,
    required this.isDark,
    required this.typeColor,
    required this.currentBalance,
    required this.projectedBalance,
  });

  @override
  Widget build(BuildContext context) {
    final currencySymbolColor =
        isExpense ? const Color(0xFFF87171) : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [typeColor.withValues(alpha: 0.12), AppColors.surface800]
              : [
                  typeColor.withValues(alpha: 0.06),
                  typeColor.withValues(alpha: 0.03),
                ],
        ),
        border: Border.all(
          color: typeColor.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: typeColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: TextStyle(
              fontSize: 38,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.textLight,
              letterSpacing: -1.0,
              height: 1.1,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? const Color(0x73FFFFFF)
                    : AppColors.textMutedL.withValues(alpha: 0.5),
                letterSpacing: -1.0,
                fontFeatures: CurrencyFormatter.tabularFigures,
              ),
              prefixText: '₱ ',
              prefixStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: currencySymbolColor,
                fontFeatures: CurrencyFormatter.tabularFigures,
              ),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              filled: false,
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Enter an amount';
              if (!RegExp(r'^\d{1,12}(\.\d{1,2})?$').hasMatch(value)) {
                return 'Use up to 2 decimal places';
              }
              final amount = double.tryParse(value);
              if (amount == null || !amount.isFinite || amount <= 0) {
                return 'Enter an amount greater than zero';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surface900.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.subtleBorder : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'New Balance: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                  ),
                ),
                Flexible(
                  child: Text(
                    '${CurrencyFormatter.format(currentBalance)} → ${CurrencyFormatter.format(projectedBalance)}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: CurrencyFormatter.tabularFigures,
                      color: isDark ? Colors.white : AppColors.textLight,
                    ),
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

// ─── Income Quick Presets ─────────────────────────────────────

class _IncomeQuickPresets extends StatelessWidget {
  final String selectedSource;
  final bool isDark;
  final ValueChanged<String> onSelect;

  static const _presets = [
    'Salary',
    'Freelance',
    'Allowance',
    'Bonus',
    'Other',
  ];

  const _IncomeQuickPresets({
    required this.selectedSource,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _presets.map((preset) {
          final isSelected =
              selectedSource.toLowerCase() == preset.toLowerCase();
          final icon = CategoryIconHelper.iconFor(preset);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: preset,
              onTap: () => onSelect(preset),
              excludeSemantics: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(preset),
                  borderRadius: BorderRadius.circular(AppTheme.tagRadius),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.income.withValues(
                              alpha: isDark ? 0.20 : 0.12,
                            )
                          : (isDark
                              ? AppColors.surface700
                              : AppColors.lightCard2),
                      borderRadius: BorderRadius.circular(AppTheme.tagRadius),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.income.withValues(
                                alpha: isDark ? 0.50 : 0.40,
                              )
                            : (isDark
                                ? AppColors.surface600
                                : AppColors.lightBorder),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected
                              ? AppColors.income
                              : (isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedL),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          preset,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.income
                                : (isDark
                                    ? AppColors.textDark
                                    : AppColors.textLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Category Grid ────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  final List<Map<String, String>> categories;
  final String? selectedId;
  final bool isDark;
  final ValueChanged<String> onSelect;

  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.isDark,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final isSelected = selectedId == cat['id'];
        final catName = cat['name'] ?? '';
        final catColor = CategoryIconHelper.colorFor(catName);
        final catIcon = CategoryIconHelper.iconFor(catName);

        return Semantics(
          button: true,
          selected: isSelected,
          label: catName,
          onTap: () => onSelect(cat['id']!),
          excludeSemantics: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelect(cat['id']!),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.expense.withValues(
                          alpha: isDark ? 0.18 : 0.10,
                        )
                      : (isDark ? AppColors.surface700 : AppColors.lightCard2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.expense.withValues(
                            alpha: isDark ? 0.40 : 0.30,
                          )
                        : (isDark
                            ? AppColors.surface600
                            : AppColors.lightBorder),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      catIcon,
                      size: 15,
                      color: isSelected ? AppColors.expense : catColor,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        catName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? AppColors.expense
                              : (isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Account Dropdown ─────────────────────────────────────────

class _AccountDropdown extends StatelessWidget {
  final List<Account> accounts;
  final String? selectedAccountId;
  final Map<String, double> accountBalances;
  final double defaultBalance;
  final bool isDark;
  final ValueChanged<String> onChanged;

  const _AccountDropdown({
    required this.accounts,
    required this.selectedAccountId,
    required this.accountBalances,
    required this.defaultBalance,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedId = (selectedAccountId != null &&
            accounts.any((a) => a.id == selectedAccountId))
        ? selectedAccountId!
        : accounts.first.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surface700.withValues(alpha: 0.5)
            : AppColors.lightCard2,
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        border: Border.all(
          color: isDark
              ? AppColors.surface600.withValues(alpha: 0.7)
              : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: effectiveSelectedId,
          isExpanded: true,
          dropdownColor: isDark ? AppColors.surface800 : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: isDark ? AppColors.textMuted : AppColors.textMutedL,
          ),
          selectedItemBuilder: (context) {
            return accounts.map((acc) {
              final accBalance = accountBalances[acc.id] ?? defaultBalance;
              return Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 18,
                    color: AppColors.emerald500,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      acc.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        color:
                            isDark ? AppColors.textDark : AppColors.textLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.format(accBalance),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      fontFeatures: CurrencyFormatter.tabularFigures,
                      color:
                          isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                ],
              );
            }).toList();
          },
          items: accounts.map((acc) {
            final isSelected = acc.id == effectiveSelectedId;
            final accBalance = accountBalances[acc.id] ?? defaultBalance;
            return DropdownMenuItem<String>(
              value: acc.id,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 18,
                      color: isSelected
                          ? AppColors.emerald500
                          : (isDark
                              ? AppColors.textMuted
                              : AppColors.textMutedL),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        acc.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                          color: isSelected
                              ? AppColors.emerald500
                              : (isDark
                                  ? AppColors.textDark
                                  : AppColors.textLight),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      CurrencyFormatter.format(accBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        fontFeatures: CurrencyFormatter.tabularFigures,
                        color: isSelected
                            ? AppColors.emerald500
                            : (isDark
                                ? AppColors.textMuted
                                : AppColors.textMutedL),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}

// ─── No Accounts Notice ───────────────────────────────────────

class _NoAccountsNotice extends StatelessWidget {
  final bool isDark;
  const _NoAccountsNotice({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface700 : AppColors.lightCard2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.surface600 : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: isDark ? AppColors.textMuted : AppColors.textMutedL,
              ),
              const SizedBox(width: 8),
              Text(
                'No accounts yet',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Create an account or wallet before recording a transaction.',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => context.push('/accounts'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create account'),
          ),
        ],
      ),
    );
  }
}

// ─── Date Picker ──────────────────────────────────────────────

class _DatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final bool isDark;
  final VoidCallback onTap;
  const _DatePicker({
    required this.selectedDate,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.inputRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface700.withValues(alpha: 0.5)
              : AppColors.lightCard2,
          borderRadius: BorderRadius.circular(AppTheme.inputRadius),
          border: Border.all(
            color: isDark
                ? AppColors.surface600.withValues(alpha: 0.7)
                : AppColors.lightBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: AppColors.emerald500,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                DateFormat('EEEE, MMM d, y').format(selectedDate),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: isDark ? AppColors.textDark : AppColors.textLight,
                ),
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 20,
              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduledDateNotice extends StatelessWidget {
  final bool isExpense;
  final DateTime selectedDate;
  final bool isDark;

  const _ScheduledDateNotice({
    required this.isExpense,
    required this.selectedDate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isExpense ? AppColors.expense : AppColors.income;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.alertRadius),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule_rounded, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '${isExpense ? 'This expense' : 'This income'} is scheduled for ${DateFormat('MMM d, yyyy').format(selectedDate)}. It will affect your current balance when the date arrives.',
              style: TextStyle(
                color: isDark ? AppColors.textDark : AppColors.textLight,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  const _FieldLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textMuted : AppColors.textMutedL,
      ),
    );
  }
}

// ─── Save Button ──────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final bool isExpense;
  final bool isSubmitting;
  final bool isEditing;
  final VoidCallback onPressed;
  final Color typeColor;

  const _SaveButton({
    required this.isExpense,
    required this.isSubmitting,
    required this.isEditing,
    required this.onPressed,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
        gradient: isSubmitting
            ? null
            : LinearGradient(
                colors: isExpense
                    ? [const Color(0xFFDC2626), AppColors.expense]
                    : [const Color(0xFF059669), AppColors.income],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: isSubmitting
            ? []
            : [
                BoxShadow(
                  color: typeColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSubmitting
              ? AppColors.surface600
              : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
          ),
          elevation: 0,
        ),
        icon: isSubmitting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Icon(
                isExpense
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 20,
              ),
        label: Text(
          isSubmitting
              ? 'Saving...'
              : '${isEditing ? "Update" : "Save"} ${isExpense ? "Expense" : "Income"}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
