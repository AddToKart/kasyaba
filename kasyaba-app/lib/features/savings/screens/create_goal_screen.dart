import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
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
    _nameController = TextEditingController(text: g?.name ?? 'New phone');
    _amountController = TextEditingController(
      text: g != null ? g.targetAmount.toStringAsFixed(0) : '30000',
    );
    _alreadySavedController = TextEditingController(
      text: g != null ? g.currentAmount.toStringAsFixed(0) : '0',
    );
    if (g?.targetDate != null) {
      _targetDate = DateTime.tryParse(g!.targetDate!);
    } else {
      // Default to 5 months in the future matching Figma "Mar 2027" style
      final now = DateTime.now();
      _targetDate = DateTime(now.year, now.month + 5, now.day);
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
    return double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
  }

  double get _alreadySaved {
    return double.tryParse(_alreadySavedController.text.replaceAll(',', '').trim()) ?? 0.0;
  }

  double get _monthlyRequired {
    final remaining = (_targetAmount - _alreadySaved).clamp(0.0, double.infinity);
    if (remaining <= 0) return 0.0;
    if (_targetDate == null) return remaining;

    final now = DateTime.now();
    final daysUntilTarget = _targetDate!.difference(now).inDays;
    if (daysUntilTarget <= 0) return remaining;

    return (remaining / daysUntilTarget) * 30.0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year, now.month + 6, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: DashboardTokens.periwinkleGray,
              onPrimary: DashboardTokens.ebony,
              surface: DashboardTokens.bigStone,
              onSurface: DashboardTokens.periwinkleGray,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _targetDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
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
        await repo.addGoal(
          name: name,
          targetAmount: target,
          targetDate: _targetDate,
        );

        if (initialSaved > 0) {
          final goals = await ref.read(goalsProvider.future);
          final created = goals.firstWhere(
            (g) => g.name == name,
            orElse: () => goals.first,
          );
          await repo.addGoalContribution(
            goalId: created.id,
            amount: initialSaved,
            notes: 'Initial savings deposit',
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to save goal: $e';
        });
      }
    }
  }

  String get goalIdOrEmpty => widget.existingGoal?.id ?? '';

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final isEditing = widget.existingGoal != null;

    final dateText = _targetDate != null
        ? DateFormat('MMM yyyy').format(_targetDate!)
        : 'Pick date';

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: DashboardTokens.ebony,
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, topPadding + 14, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Header (Node 11:1825) ──────────────────────────
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      AppHaptics.selectionClick();
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: DashboardTokens.bigStone,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: DashboardTokens.poloBlue22),
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
              const SizedBox(height: 20),

              // ── Goal Name Field (Node 11:1831) ──────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
                decoration: BoxDecoration(
                  color: DashboardTokens.bigStone,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        'Name',
                        style: GoogleFonts.dmSans(
                          color: DashboardTokens.periwinkleGraySubtitle,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: GoogleFonts.dmSans(
                          color: DashboardTokens.periwinkleGray,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'e.g. New phone',
                          hintStyle: TextStyle(color: DashboardTokens.poloBlue30),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Target Amount Hero Box (Node 11:1836) ────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 18),
                decoration: BoxDecoration(
                  color: DashboardTokens.cello60,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DashboardTokens.poloBlue30),
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
                            color: DashboardTokens.periwinkleGraySubtitle,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IntrinsicWidth(
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            onChanged: (_) => setState(() {}),
                            style: GoogleFonts.bricolageGrotesque(
                              color: DashboardTokens.periwinkleGray,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
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
                  padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 18.5),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: DashboardTokens.poloBlue22),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          'Target date',
                          style: GoogleFonts.dmSans(
                            color: DashboardTokens.periwinkleGraySubtitle,
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
                padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
                decoration: BoxDecoration(
                  color: DashboardTokens.bigStone,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        'Already saved',
                        style: GoogleFonts.dmSans(
                          color: DashboardTokens.periwinkleGraySubtitle,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _alreadySavedController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.dmSans(
                          color: DashboardTokens.periwinkleGray,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          prefixText: '₱',
                          prefixStyle: TextStyle(
                            color: DashboardTokens.periwinkleGray,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Calculation Preview Box (Node 11:1852) ───────────────
              Container(
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

              // ── CTA Button (Node 11:1860) ───────────────────────────
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardTokens.periwinkleGray,
                    foregroundColor: DashboardTokens.ebony,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: DashboardTokens.ebony,
                          ),
                        )
                      : Text(
                          isEditing ? 'Save changes' : 'Create goal',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
