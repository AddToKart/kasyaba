import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../app/theme/app_theme.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  ConsumerState<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends ConsumerState<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isExpense = true;
  bool _isSubmitting = false;
  String? _selectedCategory;
  String? _selectedAccount;
  DateTime _selectedDate = DateTime.now();

  late final AnimationController _typeController;
  late final Animation<double> _typeFade;

  final List<Map<String, String>> _categoryItems = [
    {'id': 'cat_food',      'name': 'Food & Dining',     'icon': '🍔'},
    {'id': 'cat_transport', 'name': 'Transportation',     'icon': '🚗'},
    {'id': 'cat_utilities', 'name': 'Utilities & Bills',  'icon': '⚡'},
    {'id': 'cat_rent',      'name': 'Rent & Housing',     'icon': '🏠'},
    {'id': 'cat_education', 'name': 'Education',          'icon': '🎓'},
    {'id': 'cat_shopping',  'name': 'Shopping',           'icon': '🛍️'},
    {'id': 'cat_other',     'name': 'Other',              'icon': '📦'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryItems.first['id'];
    _typeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _typeFade = CurvedAnimation(
      parent: _typeController,
      curve: Curves.easeInOut,
    );
    _typeController.forward();
  }

  @override
  void dispose() {
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
      setState(() => _isExpense = toExpense);
      _typeController.forward();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final accountIdToUse = _selectedAccount ?? 'default';
    final categoryIdToUse = _selectedCategory ?? 'cat_food';
    setState(() => _isSubmitting = true);

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    try {
      final mutator = ref.read(transactionMutatorProvider);
      if (_isExpense) {
        await mutator.addExpense(
          accountId: accountIdToUse,
          categoryId: categoryIdToUse,
          amount: amount,
          description: description,
          spentAt: _selectedDate,
          notes: notes,
        );
      } else {
        await mutator.addIncome(
          accountId: accountIdToUse,
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
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  '${_isExpense ? "Expense" : "Income"} recorded!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: _isExpense
                ? AppColors.expense
                : AppColors.income,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        );
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.expense,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
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

    final availableCategories = categoriesAsync.maybeWhen(
      data: (cats) => cats.isNotEmpty
          ? cats
              .map((c) => {'id': c.id, 'name': c.name, 'icon': '🏷️'})
              .toList()
          : _categoryItems,
      orElse: () => _categoryItems,
    );

    // Determine accent color based on type
    final typeColor = _isExpense ? AppColors.expense : AppColors.income;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.obsidian : AppColors.lightBg,

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
                color: isDark
                    ? AppColors.surface600
                    : AppColors.lightBorder,
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
            _isExpense ? 'Add Expense' : 'Add Income',
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
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── Type Switcher ────────────────────────
                _TypeSwitcher(
                  isExpense: _isExpense,
                  isDark: isDark,
                  onExpense: () => _switchType(true),
                  onIncome: () => _switchType(false),
                ),
                const SizedBox(height: 20),

                // ── Amount Card ──────────────────────────
                _AmountCard(
                  controller: _amountController,
                  isExpense: _isExpense,
                  isDark: isDark,
                  typeColor: typeColor,
                  fadeAnim: _typeFade,
                ),
                const SizedBox(height: 16),

                // ── Details Card ─────────────────────────
                ModernCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _FieldLabel(
                        label: _isExpense
                            ? 'Description'
                            : 'Income Source',
                        isDark: isDark,
                      ),
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
                            child: Icon(
                              Icons.description_outlined,
                              size: 20,
                            ),
                          ),
                        ),
                        validator: (v) => (v?.trim().length ?? 0) >= 1
                            ? null
                            : 'Description is required',
                      ),
                      const SizedBox(height: 20),

                      // Category (expense only)
                      if (_isExpense) ...[
                        _FieldLabel(
                            label: 'Category', isDark: isDark),
                        const SizedBox(height: 10),
                        _CategoryGrid(
                          categories: availableCategories,
                          selectedId: _selectedCategory,
                          isDark: isDark,
                          onSelect: (id) =>
                              setState(() => _selectedCategory = id),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Account
                      _FieldLabel(
                          label: 'Account / Wallet',
                          isDark: isDark),
                      const SizedBox(height: 10),
                      accountsAsync.when(
                        loading: () => const LinearProgressIndicator(
                          color: AppColors.emerald500,
                        ),
                        error: (_, __) => _AccountChip(
                          label: 'Cash Wallet',
                          icon: '💵',
                          isSelected: true,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        data: (accounts) {
                          if (accounts.isNotEmpty &&
                              _selectedAccount == null) {
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) {
                              if (mounted && _selectedAccount == null) {
                                setState(() =>
                                    _selectedAccount =
                                        accounts.first.id);
                              }
                            });
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: accounts.map((acc) {
                              final isSelected =
                                  _selectedAccount == acc.id ||
                                      _selectedAccount == null;
                              return _AccountChip(
                                label: acc.name,
                                icon: '💵',
                                isSelected: isSelected,
                                isDark: isDark,
                                onTap: () => setState(
                                    () => _selectedAccount = acc.id),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date
                      _FieldLabel(
                          label: 'Transaction Date',
                          isDark: isDark),
                      const SizedBox(height: 8),
                      _DatePicker(
                        selectedDate: _selectedDate,
                        isDark: isDark,
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 20),

                      // Notes
                      _FieldLabel(
                          label: 'Notes (Optional)',
                          isDark: isDark),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add details, receipts, or memos...',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 4, top: 12),
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Icon(Icons.notes_outlined, size: 20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save Button ──────────────────────────
                _SaveButton(
                  isExpense: _isExpense,
                  isSubmitting: _isSubmitting,
                  onPressed: _handleSave,
                  typeColor: typeColor,
                ),
                const SizedBox(height: 32),
              ],
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
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : Colors.transparent,
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
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedL),
                ),
              ),
            ],
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
  final Animation<double> fadeAnim;

  const _AmountCard({
    required this.controller,
    required this.isExpense,
    required this.isDark,
    required this.typeColor,
    required this.fadeAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  typeColor.withValues(alpha: 0.12),
                  AppColors.surface800,
                ]
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpense ? '↑ EXPENSE' : '↓ INCOME',
                  style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: typeColor,
              letterSpacing: -1.5,
              height: 1.1,
            ),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: typeColor.withValues(alpha: 0.3),
                letterSpacing: -1.5,
              ),
              prefixText: '₱ ',
              prefixStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: typeColor.withValues(alpha: 0.7),
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
              if (v == null || v.trim().isEmpty) return 'Enter an amount';
              if (double.tryParse(v) == null) return 'Enter a valid number';
              return null;
            },
          ),
        ],
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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = selectedId == cat['id'];
        return GestureDetector(
          onTap: () => onSelect(cat['id']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.expense.withValues(
                      alpha: isDark ? 0.18 : 0.10)
                  : (isDark
                      ? AppColors.surface700
                      : AppColors.lightCard2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.expense.withValues(
                        alpha: isDark ? 0.40 : 0.30)
                    : (isDark
                        ? AppColors.surface600
                        : AppColors.lightBorder),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cat['icon']!,
                    style: const TextStyle(fontSize: 15)),
                const SizedBox(width: 6),
                Text(
                  cat['name']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: isSelected
                        ? AppColors.expense
                        : (isDark
                            ? AppColors.textDark
                            : AppColors.textLight),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Account Chip ─────────────────────────────────────────────

class _AccountChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
  const _AccountChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.income.withValues(alpha: isDark ? 0.15 : 0.10)
              : (isDark ? AppColors.surface700 : AppColors.lightCard2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.income.withValues(alpha: isDark ? 0.40 : 0.30)
                : (isDark ? AppColors.surface600 : AppColors.lightBorder),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
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
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.surface700.withValues(alpha: 0.5)
              : AppColors.lightCard2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? AppColors.surface600.withValues(alpha: 0.7)
                : AppColors.lightBorder,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
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
                  color: isDark
                      ? AppColors.textDark
                      : AppColors.textLight,
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
  final VoidCallback onPressed;
  final Color typeColor;

  const _SaveButton({
    required this.isExpense,
    required this.isSubmitting,
    required this.onPressed,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
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
                  color: typeColor.withValues(alpha: 0.40),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isSubmitting ? AppColors.surface600 : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
              : 'Save ${isExpense ? "Expense" : "Income"}',
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
