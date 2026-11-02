import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import 'dashboard_tokens.dart';
import 'kasyaba_safe_spend_breakdown_sheet.dart';

/// ─────────────────────────────────────────────────────────────
///  KasyaBa? Purchase Simulator Modal (Nodes 85:1409, 103:158, 103:321)
/// ─────────────────────────────────────────────────────────────
void showKasyaBaAffordabilitySheet(BuildContext context) {
  ModernBottomSheet.show(
    context: context,
    title: 'KasyaBa? Purchase Simulator',
    subtitle:
        'Simulate any purchase before you spend. Evaluates bill conflicts, cash buffer, and savings goal delays.',
    showDragHandle: true,
    child: const _KasyaBaAffordabilitySheetContent(),
  );
}

class _KasyaBaAffordabilitySheetContent extends ConsumerStatefulWidget {
  const _KasyaBaAffordabilitySheetContent();

  @override
  ConsumerState<_KasyaBaAffordabilitySheetContent> createState() =>
      _KasyaBaAffordabilitySheetContentState();
}

enum _PaymentMode { payInFull, installment }

class _KasyaBaAffordabilitySheetContentState
    extends ConsumerState<_KasyaBaAffordabilitySheetContent> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(text: 'Intended Purchase');
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
                ? 'Purchase'
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Payment Mode Segmented Switch (Pay in Full vs Installment) ─
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: DashboardTokens.ebony,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Row(
            children: [
              Expanded(
                child: _ModeTabButton(
                  title: 'Pay in full',
                  isSelected: _mode == _PaymentMode.payInFull,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() => _mode = _PaymentMode.payInFull);
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _ModeTabButton(
                  title: 'Installment',
                  isSelected: _mode == _PaymentMode.installment,
                  onTap: () {
                    AppHaptics.selectionClick();
                    setState(() => _mode = _PaymentMode.installment);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Input Container (Node 85:1409) ───────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PURCHASE DETAILS',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 12),

              // Item title
              TextField(
                controller: _titleController,
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGray,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  labelText: 'What do you want to buy?',
                  labelStyle: GoogleFonts.dmSans(
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                  filled: true,
                  fillColor: DashboardTokens.ebony.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: DashboardTokens.periwinkleGray),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.bricolageGrotesque(
                  color: DashboardTokens.periwinkleGray,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: GoogleFonts.bricolageGrotesque(
                    color: DashboardTokens.periwinkleGray,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  labelText: 'Amount',
                  labelStyle: GoogleFonts.dmSans(
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                  filled: true,
                  fillColor: DashboardTokens.ebony.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: DashboardTokens.periwinkleGray),
                  ),
                ),
              ),

              // ── Installment Configuration (Node 103:321) ───────────
              if (_mode == _PaymentMode.installment) ...[
                const SizedBox(height: 14),
                Text(
                  'TENURE',
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [3, 6, 12, 24].map((tenure) {
                    final isSelected = _tenureMonths == tenure;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: GestureDetector(
                          onTap: () {
                            AppHaptics.selectionClick();
                            setState(() => _tenureMonths = tenure);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            height: 38,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? DashboardTokens.periwinkleGray
                                  : DashboardTokens.ebony
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? DashboardTokens.periwinkleGray
                                    : DashboardTokens.poloBlue22,
                              ),
                            ),
                            child: Text(
                              '${tenure}m',
                              style: GoogleFonts.dmSans(
                                color: isSelected
                                    ? DashboardTokens.ebony
                                    : DashboardTokens.periwinkleGraySubtitle,
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
                const SizedBox(height: 12),
                TextField(
                  controller: _interestRateController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.dmSans(
                    color: DashboardTokens.periwinkleGray,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    suffixText: '% / mo',
                    suffixStyle: GoogleFonts.dmSans(
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                    labelText: 'Monthly interest rate (0% for 0% BNPL)',
                    labelStyle: GoogleFonts.dmSans(
                      color: DashboardTokens.periwinkleGraySubtitle,
                      fontSize: 12,
                    ),
                    filled: true,
                    fillColor: DashboardTokens.ebony.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: DashboardTokens.poloBlue22),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: DashboardTokens.poloBlue22),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: DashboardTokens.periwinkleGray),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Evaluate Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _evaluate,
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardTokens.periwinkleGray,
                    foregroundColor: DashboardTokens.ebony,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
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
                          _mode == _PaymentMode.payInFull
                              ? 'Forecast Pay in Full'
                              : 'Forecast Installment',
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

        // ── Simulation Result (Nodes 103:158 & 103:321) ──────────────
        if (_result != null) ...[
          const SizedBox(height: 16),
          _SimulationResultCard(
            result: _result!,
            mode: _mode,
            installmentComp: installmentComp,
            onViewMathBreakdown: () =>
                showSafeSpendBreakdownSheet(context, safeSpendCalc),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

/// ── Mode Tab Button ─────────────────────────────────────────────────────
class _ModeTabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? DashboardTokens.periwinkleGray
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: GoogleFonts.dmSans(
            color: isSelected
                ? DashboardTokens.ebony
                : DashboardTokens.periwinkleGraySubtitle,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// ── Result Card (Pay in Full & Installment) ──────────────────────────────
class _SimulationResultCard extends StatelessWidget {
  final PurchaseCheckResult result;
  final _PaymentMode mode;
  final InstallmentComparison? installmentComp;
  final VoidCallback onViewMathBreakdown;

  const _SimulationResultCard({
    required this.result,
    required this.mode,
    required this.installmentComp,
    required this.onViewMathBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final isAffordable = result.verdict.toUpperCase() == 'AFFORDABLE';
    final accentColor =
        isAffordable ? DashboardTokens.bermuda : DashboardTokens.apricot;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAffordable
                      ? Icons.check_circle_rounded
                      : Icons.warning_amber_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.statusTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.statusMessage,
                      style: GoogleFonts.dmSans(
                        fontSize: 12.5,
                        color: DashboardTokens.periwinkleGraySubtitle,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: DashboardTokens.poloBlue22, height: 1),
          const SizedBox(height: 14),

          // Pay in Full Metrics
          if (mode == _PaymentMode.payInFull) ...[
            _MetricRow(
              label: 'Cash after upcoming bills',
              value: CurrencyFormatter.format(result.cashAfterBills),
              valueColor: DashboardTokens.periwinkleGray,
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Post-purchase liquid balance',
              value: CurrencyFormatter.format(result.postPurchaseBalance),
              valueColor: result.postPurchaseBalance > 0
                  ? DashboardTokens.bermuda
                  : DashboardTokens.apricot,
            ),
          ] else if (installmentComp != null) ...[
            // Installment Metrics (Node 103:321)
            _MetricRow(
              label: 'Monthly payment (${installmentComp!.tenureMonths} mos)',
              value:
                  '${CurrencyFormatter.format(installmentComp!.monthlyInstallment)} / mo',
              valueColor: DashboardTokens.periwinkleGray,
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Cash preserved today',
              value:
                  '+${CurrencyFormatter.format(installmentComp!.cashPreservedToday)}',
              valueColor: DashboardTokens.bermuda,
            ),
            const SizedBox(height: 8),
            _MetricRow(
              label: 'Daily safe spend reduction',
              value:
                  '-${CurrencyFormatter.format(installmentComp!.installmentDailySafeSpendImpact)} / day',
              valueColor: DashboardTokens.poloBlue,
            ),
          ],

          const SizedBox(height: 16),

          // Math Breakdown Link Button (Node 79:104)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onViewMathBreakdown,
              icon: const Icon(
                Icons.calculate_outlined,
                size: 16,
                color: DashboardTokens.periwinkleGray,
              ),
              label: Text(
                'View Math Breakdown',
                style: GoogleFonts.dmSans(
                  color: DashboardTokens.periwinkleGray,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
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
            fontSize: 13,
            color: DashboardTokens.periwinkleGraySubtitle,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
            fontFeatures: CurrencyFormatter.tabularFigures,
          ),
        ),
      ],
    );
  }
}
