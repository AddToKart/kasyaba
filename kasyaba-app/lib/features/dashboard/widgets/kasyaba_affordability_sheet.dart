import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import 'dashboard_tokens.dart';
import 'kasyaba_safe_spend_breakdown_sheet.dart';

/// ─────────────────────────────────────────────────────────────
///  KasyaBa? Purchase Simulator Modal (Nodes 85:1409, 103:158, 103:321)
/// ─────────────────────────────────────────────────────────────
void showKasyaBaAffordabilitySheet(BuildContext context) {
  final topPadding = MediaQuery.paddingOf(context).top;
  final screenHeight = MediaQuery.sizeOf(context).height;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.75),
    constraints: BoxConstraints(
      maxHeight: screenHeight - topPadding - 32,
    ),
    builder: (ctx) => const _KasyaBaAffordabilitySheetModal(),
  );
}

class _KasyaBaAffordabilitySheetModal extends ConsumerStatefulWidget {
  const _KasyaBaAffordabilitySheetModal();

  @override
  ConsumerState<_KasyaBaAffordabilitySheetModal> createState() =>
      _KasyaBaAffordabilitySheetModalState();
}

enum _PaymentMode { payInFull, installment }

class _KasyaBaAffordabilitySheetModalState
    extends ConsumerState<_KasyaBaAffordabilitySheetModal> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _interestRateController = TextEditingController(text: '0.0');

  _PaymentMode _mode = _PaymentMode.payInFull;
  int _tenureMonths = 3;
  bool _isLoading = false;
  PurchaseCheckResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _interestRateController.dispose();
    super.dispose();
  }

  Future<void> _evaluate() async {
    final rawAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (rawAmount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid purchase amount.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref
          .read(transactionMutatorProvider)
          .evaluatePurchaseCheck(
            itemTitle: _titleController.text.trim().isEmpty
                ? 'Intended Purchase'
                : _titleController.text.trim(),
            amount: rawAmount,
          );
      if (mounted) {
        setState(() {
          _result = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not evaluate purchase check: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final bills = ref.watch(billsProvider).valueOrNull ?? [];
    final goals = ref.watch(goalsProvider).valueOrNull ?? [];
    final dashboard = ref.watch(dashboardProvider).valueOrNull;

    final safeSpendCalc = calculateDailySafeSpend(
      totalLiquidBalance: dashboard?.totalBalance ?? 0.0,
      bills: bills,
      goals: goals,
      profile: userProfile,
    );

    final rawAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final interestRate =
        double.tryParse(_interestRateController.text.trim()) ?? 0.0;

    final monthlySalary = userProfile?.salaryAmount != null &&
            userProfile!.salaryAmount! > 0
        ? userProfile.salaryAmount!
        : 45000.0;
    final workHours = calculateWorkHoursEquivalent(
      itemPrice: rawAmount > 0 ? rawAmount : 50000.0,
      monthlySalary: monthlySalary,
    );

    InstallmentComparison? installmentComp;
    if (rawAmount > 0) {
      installmentComp = calculateInstallmentComparison(
        purchaseAmount: rawAmount,
        tenureMonths: _tenureMonths,
        monthlyInterestRatePercent: interestRate,
        currentBalance: dashboard?.totalBalance ?? 0.0,
        daysUntilPayday: safeSpendCalc.daysUntilPayday,
      );
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxAllowedHeight = screenHeight - topPadding - 32;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxAllowedHeight,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: DashboardTokens.ebony,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(
            top: BorderSide(color: DashboardTokens.poloBlue22, width: 1.0),
          ),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ──────────────────────────────────────
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DashboardTokens.poloBlue22.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // ── Modal Header (Figma Node 85:1409 Carbon Copy) ────
              Text(
                'Evaluate affordability',
                style: GoogleFonts.bricolageGrotesque(
                  color: DashboardTokens.periwinkleGray,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Deterministic calculation of life–energy work hours, cash flow, and installment impact.',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGraySubtitle,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // ── Card Container with Inputs & Mode Switch ─────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DashboardTokens.bigStone,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ITEM / PURCHASE NAME Label & Round Pill Input (Node 11:808 Style)
                    Text(
                      'ITEM / PURCHASE NAME',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 54,
                      child: TextField(
                        controller: _titleController,
                        style: GoogleFonts.dmSans(
                          color: DashboardTokens.periwinkleGray,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'e.g. Laptop',
                          hintStyle: GoogleFonts.dmSans(
                            color: DashboardTokens.periwinkleGraySubtitle
                                .withValues(alpha: 0.45),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor:
                              DashboardTokens.ebony.withValues(alpha: 0.55),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: DashboardTokens.poloBlue22,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: DashboardTokens.poloBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ITEM PRICE (₱) Label & Round Pill Input (Node 11:808 Style)
                    Text(
                      'ITEM PRICE (₱)',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 54,
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: GoogleFonts.dmSans(
                          color: DashboardTokens.periwinkleGray,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          prefixText: '₱  ',
                          prefixStyle: GoogleFonts.dmSans(
                            color: DashboardTokens.periwinkleGray,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          hintText: '50,000',
                          hintStyle: GoogleFonts.dmSans(
                            color: DashboardTokens.periwinkleGraySubtitle
                                .withValues(alpha: 0.45),
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor:
                              DashboardTokens.ebony.withValues(alpha: 0.55),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: DashboardTokens.poloBlue22,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(27),
                            borderSide: const BorderSide(
                              color: DashboardTokens.poloBlue,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Sliding Segmented Switcher (Smooth Gliding Pill) ──
                    _SlidingSegmentedSwitcher(
                      mode: _mode,
                      onModeChanged: (newMode) {
                        setState(() => _mode = newMode);
                      },
                    ),

                    // ── Animated Expansion for Installment Options ──
                    ClipRRect(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _mode == _PaymentMode.installment
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 18),
                                  Text(
                                    'INSTALLMENT TENURE',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [3, 6, 12, 24].map((tenure) {
                                      final isSelected =
                                          _tenureMonths == tenure;
                                      return Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          child: GestureDetector(
                                            onTap: () {
                                              AppHaptics.selectionClick();
                                              setState(() =>
                                                  _tenureMonths = tenure);
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                  milliseconds: 180),
                                              curve: Curves.easeOutCubic,
                                              height: 42,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isSelected
                                                    ? DashboardTokens
                                                        .periwinkleGray
                                                    : DashboardTokens.ebony
                                                        .withValues(
                                                            alpha: 0.55),
                                                borderRadius:
                                                    BorderRadius.circular(21),
                                                border: Border.all(
                                                  color: isSelected
                                                      ? DashboardTokens
                                                          .periwinkleGray
                                                      : DashboardTokens
                                                          .poloBlue22,
                                                ),
                                              ),
                                              child: Text(
                                                '${tenure}m',
                                                style: GoogleFonts.dmSans(
                                                  color: isSelected
                                                      ? DashboardTokens.ebony
                                                      : DashboardTokens
                                                          .periwinkleGraySubtitle,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'MONTHLY INTEREST RATE',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  SizedBox(
                                    height: 54,
                                    child: TextField(
                                      controller: _interestRateController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.dmSans(
                                        color: DashboardTokens.periwinkleGray,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        hintText: '0.0 (0% for 0% BNPL)',
                                        hintStyle: GoogleFonts.dmSans(
                                          color: DashboardTokens
                                              .periwinkleGraySubtitle
                                              .withValues(alpha: 0.45),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        suffixText: '% / mo',
                                        suffixStyle: GoogleFonts.dmSans(
                                          color: DashboardTokens
                                              .periwinkleGraySubtitle,
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        filled: true,
                                        fillColor: DashboardTokens.ebony
                                            .withValues(alpha: 0.55),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 22,
                                          vertical: 16,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(27),
                                          borderSide: const BorderSide(
                                            color: DashboardTokens.poloBlue22,
                                            width: 1.0,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(27),
                                          borderSide: const BorderSide(
                                            color: DashboardTokens.poloBlue,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ── Action Button (Below Card, Full Width Pill) ────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _evaluate,
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardTokens.periwinkleGray,
                    foregroundColor: DashboardTokens.ebony,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: DashboardTokens.ebony,
                          ),
                        )
                      : Text(
                          'Evaluate affordability',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.dmSans(
                    color: DashboardTokens.apricot,
                    fontSize: 12,
                  ),
                ),
              ],

              // ── Formal Simulation Result Section (Image 2) ──────
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: _result != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 18),
                          _SimulationResultCard(
                            result: _result!,
                            mode: _mode,
                            rawAmount: rawAmount,
                            workHours: workHours,
                            safeSpendCalc: safeSpendCalc,
                            installmentComp: installmentComp,
                            onViewMathBreakdown: () {
                              Navigator.of(context).pop();
                              showSafeSpendBreakdownSheet(
                                  context, safeSpendCalc);
                            },
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Sliding Segmented Switcher (Smooth Moving Pill Indicator) ───────────
class _SlidingSegmentedSwitcher extends StatelessWidget {
  final _PaymentMode mode;
  final ValueChanged<_PaymentMode> onModeChanged;

  const _SlidingSegmentedSwitcher({
    required this.mode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPayInFull = mode == _PaymentMode.payInFull;

    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DashboardTokens.ebony,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: DashboardTokens.poloBlue22),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;

          return Stack(
            children: [
              // Animated Smooth Gliding Background Pill
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                left: isPayInFull ? 0 : pillWidth,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: DashboardTokens.periwinkleGray,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Option Tab Labels
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (mode != _PaymentMode.payInFull) {
                          AppHaptics.selectionClick();
                          onModeChanged(_PaymentMode.payInFull);
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: double.infinity,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          style: GoogleFonts.dmSans(
                            color: isPayInFull
                                ? DashboardTokens.ebony
                                : DashboardTokens.periwinkleGraySubtitle,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: const Text('Pay in full'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (mode != _PaymentMode.installment) {
                          AppHaptics.selectionClick();
                          onModeChanged(_PaymentMode.installment);
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        height: double.infinity,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          style: GoogleFonts.dmSans(
                            color: !isPayInFull
                                ? DashboardTokens.ebony
                                : DashboardTokens.periwinkleGraySubtitle,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          child: const Text('Installment'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// ── Result Section (Formal View Matching Image 2) ────────────────────────
class _SimulationResultCard extends StatelessWidget {
  final PurchaseCheckResult result;
  final _PaymentMode mode;
  final double rawAmount;
  final WorkHoursEquivalent workHours;
  final DailySafeSpendCalculation safeSpendCalc;
  final InstallmentComparison? installmentComp;
  final VoidCallback onViewMathBreakdown;

  const _SimulationResultCard({
    required this.result,
    required this.mode,
    required this.rawAmount,
    required this.workHours,
    required this.safeSpendCalc,
    required this.installmentComp,
    required this.onViewMathBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final isAffordable = result.verdict.toUpperCase() == 'AFFORDABLE';
    final accentColor =
        isAffordable ? DashboardTokens.bermuda : DashboardTokens.apricot;

    final safeSpendReduction = safeSpendCalc.daysUntilPayday > 0
        ? (rawAmount / safeSpendCalc.daysUntilPayday)
        : rawAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Card 1: Safely affordable / Insufficient Funds Status ──
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: DashboardTokens.poloBlue22,
              width: 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.statusTitle,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                result.statusMessage,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: DashboardTokens.periwinkleGraySubtitle,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),

              // Recessed Life-Energy Work Hours Box
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF101E31),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${workHours.workHours.toStringAsFixed(1)} work hours · ${workHours.workDays.toStringAsFixed(1)} workdays',
                      style: GoogleFonts.dmSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Based on ${CurrencyFormatter.format(workHours.salaryAmount ?? 45000, decimalDigits: 0)} a month, ${CurrencyFormatter.format(workHours.hourlyWage > 0 ? workHours.hourlyWage : 255.68)} per hour, 176 work hours a month.',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: DashboardTokens.periwinkleGraySubtitle,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Section Header: Payment details ────────────────────────
        Text(
          'Payment details',
          style: GoogleFonts.bricolageGrotesque(
            color: DashboardTokens.periwinkleGray,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // ── Card 2: Payment details Formal Card ────────────────────
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  mode == _PaymentMode.payInFull
                      ? 'PAY IN FULL'
                      : 'INSTALLMENT (${installmentComp?.tenureMonths ?? 3}M)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _MetricRow(
                label: 'Paid today',
                value: mode == _PaymentMode.payInFull
                    ? '-${CurrencyFormatter.format(rawAmount)}'
                    : '-${CurrencyFormatter.format(installmentComp?.monthlyInstallment ?? (rawAmount / 3))}',
                valueColor: DashboardTokens.apricot,
              ),
              const SizedBox(height: 14),
              _MetricRow(
                label: 'Cash left',
                value: CurrencyFormatter.format(
                  mode == _PaymentMode.payInFull
                      ? result.postPurchaseBalance
                      : (installmentComp?.postCashBalance ??
                          result.postPurchaseBalance),
                ),
                valueColor: DashboardTokens.periwinkleGray,
              ),
              const SizedBox(height: 14),
              _MetricRow(
                label: 'Safe per day',
                value: mode == _PaymentMode.payInFull
                    ? '-${CurrencyFormatter.format(safeSpendReduction)}'
                    : '-${CurrencyFormatter.format(installmentComp?.installmentDailySafeSpendImpact ?? 0)}',
                valueColor: DashboardTokens.apricot,
              ),
              if (mode == _PaymentMode.installment) ...[
                const SizedBox(height: 14),
                _MetricRow(
                  label: 'Interest',
                  value: (installmentComp?.totalInterest ?? 0) == 0
                      ? '₱0'
                      : CurrencyFormatter.format(
                          installmentComp!.totalInterest),
                  valueColor: (installmentComp?.totalInterest ?? 0) == 0
                      ? DashboardTokens.bermuda
                      : DashboardTokens.apricot,
                ),
              ],
              const SizedBox(height: 16),

              // View Math Breakdown Link Button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: onViewMathBreakdown,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calculate_outlined,
                          size: 16,
                          color: DashboardTokens.periwinkleGray,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View Math Breakdown',
                          style: GoogleFonts.dmSans(
                            color: DashboardTokens.periwinkleGray,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _MetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: DashboardTokens.periwinkleGraySubtitle,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFeatures: CurrencyFormatter.tabularFigures,
          ),
        ),
      ],
    );
  }
}
