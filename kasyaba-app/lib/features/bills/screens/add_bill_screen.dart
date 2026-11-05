import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/kasyaba_date_picker.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// ─────────────────────────────────────────────────────────────
///  Add New Bill Screen (Figma Node 42:6794)
/// ─────────────────────────────────────────────────────────────
class AddBillScreen extends ConsumerStatefulWidget {
  final String? initialName;

  const AddBillScreen({super.key, this.initialName});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  final _amountController = TextEditingController();

  DateTime _dueDate = _dateOnly(DateTime.now().add(const Duration(days: 7)));
  String _repeats = 'Monthly'; // 'Once', 'Weekly', 'Monthly'
  String _remindMe = '1 day before';
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isSubmitting = false;

  static const List<String> _repeatOptions = ['Once', 'Weekly', 'Monthly'];
  static const List<String> _remindOptions = [
    'On the day',
    '1 day before',
    '3 days before',
    '1 week before',
  ];
  static const Map<String, int> _remindLeadDays = {
    'On the day': 0,
    '1 day before': 1,
    '3 days before': 3,
    '1 week before': 7,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _handleClose() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/bills');
    }
  }

  Future<void> _pickDueDate() async {
    AppHaptics.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (ctx, child) {
        if (child == null) return const SizedBox.shrink();
        return Theme(data: kasyabaDatePickerTheme(ctx), child: child);
      },
    );
    if (picked != null && mounted) {
      setState(() => _dueDate = _dateOnly(picked));
    }
  }

  Future<void> _showCategoryPicker() async {
    AppHaptics.selectionClick();
    final cached = ref.read(categoriesProvider).valueOrNull;
    List<Category> categories;
    if (cached != null && cached.isNotEmpty) {
      categories = cached;
    } else {
      try {
        categories = await ref.read(categoriesProvider.future);
      } catch (_) {
        categories = const [];
      }
    }
    if (!mounted) return;

    if (categories.isEmpty) {
      KasyabaToast.showInfo(
        context,
        'Categories unavailable',
        subtitle: 'You can still save this bill without a category.',
      );
      return;
    }

    final chosen = await showKasyabaSheet<Category>(
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
                    itemCount: categories.length + 1,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: DashboardTokens.poloBlue16),
                    itemBuilder: (ctx, idx) {
                      if (idx == 0) {
                        final isSelected = _selectedCategoryId == null;
                        return ListTile(
                          title: Text(
                            'No category',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected
                                  ? DashboardTokens.bermuda
                                  : DashboardTokens.periwinkleGray,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: DashboardTokens.bermuda,
                                  size: 20,
                                )
                              : null,
                          onTap: () => Navigator.of(
                            sheetContext,
                          ).pop(const Category(id: '', name: 'No category')),
                        );
                      }
                      final category = categories[idx - 1];
                      final isSelected = _selectedCategoryId == category.id;
                      return ListTile(
                        title: Text(
                          category.name,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected
                                ? DashboardTokens.bermuda
                                : DashboardTokens.periwinkleGray,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_rounded,
                                color: DashboardTokens.bermuda,
                                size: 20,
                              )
                            : null,
                        onTap: () => Navigator.of(sheetContext).pop(category),
                      );
                    },
              ),
            ],
          ),
        ),
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() {
        _selectedCategoryId = chosen.id.isEmpty ? null : chosen.id;
        _selectedCategoryName = chosen.id.isEmpty ? null : chosen.name;
      });
    }
  }

  Future<void> _handleSave() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      KasyabaToast.showError(context, 'Please enter a bill name.');
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
    if (amount <= 0) {
      KasyabaToast.showError(context, 'Please enter a valid bill amount.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      AppHaptics.mediumImpact();
      final mutator = ref.read(transactionMutatorProvider);
      final recurrencePayload = switch (_repeats.toLowerCase()) {
        'once' => 'none',
        'weekly' => 'weekly',
        'monthly' => 'monthly',
        _ => 'monthly',
      };
      await mutator.addBill(
        name: name,
        amount: amount,
        startsOn: _dueDate,
        recurrence: recurrencePayload,
        categoryId: _selectedCategoryId,
        reminderLeadDays: _remindLeadDays[_remindMe] ?? 1,
      );

      if (mounted) {
        KasyabaToast.showSuccess(
          context,
          'Bill reminder saved!',
          subtitle: '$name due ${DateFormat('MMM d').format(_dueDate)}',
        );
        _handleClose();
      }
    } catch (e) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            e,
            fallback: 'Could not save bill. Please try again.',
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
                  // ── Top Header Row (Back Button + Title) (Node 11:1515) ─────
                  Row(
                    children: [
                      SpringTouch(
                        scaleDown: 0.90,
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
                          'New bill',
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

                  // ── Name Card (Node 11:1521) ────────────────────────────────
                  _buildInputRowCard(
                    label: 'Name',
                    child: TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                      cursorColor: DashboardTokens.periwinkleGray,
                      decoration: InputDecoration(
                        hintText: 'e.g. Internet bill',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.periwinkleGray.withValues(
                            alpha: 0.4,
                          ),
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

                  // ── Hero Amount Card (Node 11:1526) ─────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 21,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '₱',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: IntrinsicWidth(
                            child: TextFormField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGray,
                                height: 1.1,
                              ),
                              textAlign: TextAlign.left,
                              cursorColor: DashboardTokens.periwinkleGray,
                              decoration: InputDecoration(
                                hintText: '0',
                                hintStyle: GoogleFonts.bricolageGrotesque(
                                  fontSize: 44,
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
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Due Date Card (Node 11:1530) ────────────────────────────
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _pickDueDate,
                    child: _buildInputRowCard(
                      label: 'Due date',
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_dueDate),
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.periwinkleGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── REPEATS Section (Node 11:1535) ──────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REPEATS',
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
                        children: _repeatOptions.map((opt) {
                          final isSelected = _repeats == opt;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              AppHaptics.selectionClick();
                              setState(() => _repeats = opt);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 17,
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
                                        color: DashboardTokens.poloBlue
                                            .withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                              ),
                              child: Text(
                                opt,
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

                  // ── REMIND ME Section (Node 11:1545) ────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REMIND ME',
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
                        children: _remindOptions.map((opt) {
                          final isSelected = _remindMe == opt;
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              AppHaptics.selectionClick();
                              setState(() => _remindMe = opt);
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
                                        color: DashboardTokens.poloBlue
                                            .withValues(alpha: 0.4),
                                        width: 1,
                                      ),
                              ),
                              child: Text(
                                opt,
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

                  // ── Category Card (Node 11:1564) ────────────────────────────
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _showCategoryPicker,
                    child: _buildInputRowCard(
                      label: 'Category',
                      child: Text(
                        _selectedCategoryName ?? 'Select category',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _selectedCategoryName == null
                              ? DashboardTokens.periwinkleGraySubtitle
                              : DashboardTokens.periwinkleGray,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── CTA Button (Node 11:1570) ───────────────────────────────
                  PillButton(
                    label: 'Save bill',
                    onPressed: _isSubmitting ? null : _handleSave,
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
            width: 96,
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
}
