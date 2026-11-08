import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../core/utils/validated_input.dart';
import '../../../shared/widgets/kasyaba_background.dart';
import '../../../shared/widgets/kasyaba_date_picker.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Create / Edit Goal Screen (Figma Node 42:6654)
/// ─────────────────────────────────────────────────────────────
class CreateGoalScreen extends ConsumerStatefulWidget {
  final SavingsGoal? existingGoal;

  const CreateGoalScreen({super.key, this.existingGoal});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _alreadySavedController;
  DateTime? _targetDate;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final g = widget.existingGoal;
    _nameController = TextEditingController(text: g?.name ?? '');
    _amountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(0) : '',
    );
    _alreadySavedController = TextEditingController(
      text: g != null ? g.currentAmount.toStringAsFixed(0) : '',
    );
    if (g?.targetDate != null) {
      _targetDate = DateTime.tryParse(g!.targetDate!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _alreadySavedController.dispose();
    super.dispose();
  }

  double get _targetAmount {
    return double.tryParse(_amountController.text.replaceAll(',', '').trim()) ??
        0.0;
  }

  double get _alreadySaved {
    return double.tryParse(
          _alreadySavedController.text.replaceAll(',', '').trim(),
        ) ??
        0.0;
  }

  double get _monthlyRequired {
    if (_targetAmount <= 0) return 0.0;

    return goalMonthlyNeed(
      SavingsGoal(
        id: widget.existingGoal?.id ?? 'preview',
        name: _nameController.text.trim(),
        targetAmount: _targetAmount,
        currentAmount: _alreadySaved,
        targetDate: _targetDate?.toIso8601String(),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year, now.month + 6, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(data: kasyabaDatePickerTheme(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!ref.read(isOnlineProvider)) {
      setState(
        () => _errorMessage =
            'Creating or editing goals needs an internet connection.',
      );
      return;
    }
    final name = _nameController.text.trim();
    final target = _targetAmount;
    final initialSaved = _alreadySaved;

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a goal name');
      return;
    }
    if (target <= 0) {
      setState(() => _errorMessage = 'Please enter a valid target amount');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      AppHaptics.mediumImpact();
      final repo = ref.read(budgetRepositoryProvider);
      if (widget.existingGoal != null) {
        await repo.updateGoal(
          goalId: widget.existingGoal!.id,
          name: name,
          targetAmount: target,
          targetDate: _targetDate,
        );
      } else {
        final created = await repo.addGoal(
          name: name,
          targetAmount: target,
          targetDate: _targetDate,
        );

        if (created != null && initialSaved > 0) {
          await repo.addGoalContribution(
            goalId: created.id,
            amount: initialSaved,
            notes: 'Initial savings deposit',
          );
        }
      }

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/goals');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = friendlyErrorMessage(
            e,
            fallback: 'Could not save goal. Please try again.',
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isEditing = widget.existingGoal != null;
    final isOnline = ref.watch(isOnlineProvider);

    final dateText = _targetDate != null
        ? DateFormat('MMM yyyy').format(_targetDate!)
        : 'Pick date';

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
        body: KasyabaBackground(
          child: SizedBox.expand(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                topPadding + 14,
                20,
                DashboardTokens.dockClearance,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top Header (Node 11:1825) ──────────────────────────
                  FadeSlideEntrance.staggered(
                    index: 0,
                    child: Row(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            AppHaptics.selectionClick();
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/goals');
                            }
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: DashboardTokens.bigStone,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: DashboardTokens.poloBlue22,
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: DashboardTokens.periwinkleGray,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          isEditing ? 'Edit goal' : 'New goal',
                          style: GoogleFonts.bricolageGrotesque(
                            color: DashboardTokens.periwinkleGray,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Goal Form Fields ──────────────────────────────────
                  FadeSlideEntrance.staggered(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Goal Name Field (Node 11:1831) ──────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 21,
                            vertical: 18.5,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardTokens.bigStone,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: DashboardTokens.poloBlue22,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 96,
                                child: Text(
                                  'Name',
                                  style: GoogleFonts.dmSans(
                                    color:
                                        DashboardTokens.periwinkleGraySubtitle,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  maxLength: kMaxNameLength,
                                  buildCounter:
                                      (
                                        context, {
                                        required currentLength,
                                        required isFocused,
                                        maxLength,
                                      }) => null,
                                  style: GoogleFonts.dmSans(
                                    color: DashboardTokens.periwinkleGray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: 'e.g. New phone',
                                    hintStyle: TextStyle(
                                      color: DashboardTokens.poloBlue30,
                                    ),
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
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Target Amount Hero Box (Node 11:1836) ────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 21,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardTokens.cello60,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: DashboardTokens.poloBlue30,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '₱',
                                    style: GoogleFonts.bricolageGrotesque(
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IntrinsicWidth(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        minWidth: 96,
                                      ),
                                      child: TextField(
                                        controller: _amountController,
                                        inputFormatters: [
                                          currencyAmountInputFormatter,
                                        ],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        textAlign: TextAlign.center,
                                        onChanged: (_) => setState(() {}),
                                        style: GoogleFonts.bricolageGrotesque(
                                          color: DashboardTokens.periwinkleGray,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        decoration: const InputDecoration(
                                          isDense: true,
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
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target amount',
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Target Date Field (Node 11:1842) ────────────────────
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 21,
                              vertical: 18.5,
                            ),
                            decoration: BoxDecoration(
                              color: DashboardTokens.bigStone,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: DashboardTokens.poloBlue22,
                              ),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 96,
                                  child: Text(
                                    'Target date',
                                    style: GoogleFonts.dmSans(
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    dateText,
                                    style: GoogleFonts.dmSans(
                                      color: DashboardTokens.periwinkleGray,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 18,
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Already Saved Field (Node 11:1847) ───────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 21,
                            vertical: 18.5,
                          ),
                          decoration: BoxDecoration(
                            color: DashboardTokens.bigStone,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: DashboardTokens.poloBlue22,
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 96,
                                child: Text(
                                  'Already saved',
                                  style: GoogleFonts.dmSans(
                                    color:
                                        DashboardTokens.periwinkleGraySubtitle,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '₱',
                                style: GoogleFonts.dmSans(
                                  color: DashboardTokens.periwinkleGray,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextField(
                                  controller: _alreadySavedController,
                                  inputFormatters: [
                                    currencyAmountInputFormatter,
                                  ],
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (_) => setState(() {}),
                                  style: GoogleFonts.dmSans(
                                    color: DashboardTokens.periwinkleGray,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    hintText: '0',
                                    hintStyle: TextStyle(
                                      color: DashboardTokens.poloBlue30,
                                    ),
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Calculation Preview Box (Node 11:1852) ───────────────
                  FadeSlideEntrance.staggered(
                    index: 2,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: DashboardTokens.bigStone,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: DashboardTokens.poloBlue22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You would need about',
                            style: GoogleFonts.dmSans(
                              color: DashboardTokens.periwinkleGraySubtitle,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${CurrencyFormatter.format(_monthlyRequired, decimalDigits: 0)} a month',
                            style: GoogleFonts.bricolageGrotesque(
                              color: DashboardTokens.bermuda,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This comes out of your safe-to-spend each day,\nso you will see it in your daily number.',
                            style: GoogleFonts.dmSans(
                              color: DashboardTokens.periwinkleGraySubtitle,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        color: DashboardTokens.apricot,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  if (!isOnline) ...[
                    NeedsInternetNotice(
                      message: isEditing
                          ? 'Editing a goal needs an internet connection.'
                          : 'Creating a goal needs an internet connection.',
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── CTA Button (Node 11:1860) ───────────────────────────
                  FadeSlideEntrance.staggered(
                    index: 3,
                    child: PillButton(
                      label: isEditing ? 'Save changes' : 'Create goal',
                      onPressed: _isSubmitting || !isOnline
                          ? null
                          : _handleSubmit,
                      isLoading: _isSubmitting,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
