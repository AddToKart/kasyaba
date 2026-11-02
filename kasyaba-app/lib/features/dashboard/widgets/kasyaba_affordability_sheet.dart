import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import 'dashboard_tokens.dart';

void showKasyaBaAffordabilitySheet(BuildContext context) {
  ModernBottomSheet.show(
    context: context,
    title: 'KasyaBa? Purchase Simulator',
    subtitle: 'Check deterministically whether you can safely afford a purchase today.',
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

class _KasyaBaAffordabilitySheetContentState
    extends ConsumerState<_KasyaBaAffordabilitySheetContent> {
  final _amountController = TextEditingController();
  final _titleController = TextEditingController(text: 'Intended Purchase');
  bool _isLoading = false;
  PurchaseCheckResult? _result;
  String? _errorMessage;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
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
      final res = await ref.read(transactionMutatorProvider).evaluatePurchaseCheck(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Input Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(20),
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
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DashboardTokens.periwinkleGray),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Amount
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.bricolageGrotesque(
                  color: DashboardTokens.periwinkleGray,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  prefixStyle: GoogleFonts.bricolageGrotesque(
                    color: DashboardTokens.periwinkleGray,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  labelText: 'Amount',
                  labelStyle: GoogleFonts.dmSans(
                    color: DashboardTokens.periwinkleGraySubtitle,
                  ),
                  filled: true,
                  fillColor: DashboardTokens.ebony.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DashboardTokens.poloBlue22),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: DashboardTokens.periwinkleGray),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Test Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: _isLoading ? null : _evaluate,
                  style: FilledButton.styleFrom(
                    backgroundColor: DashboardTokens.periwinkleGray,
                    foregroundColor: DashboardTokens.ebony,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DashboardTokens.ebony,
                          ),
                        )
                      : Text(
                          'Test "KasyaBa?"',
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
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

        // Result Card
        if (_result != null) ...[
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final isAffordable = _result!.verdict.toUpperCase() == 'AFFORDABLE';
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isAffordable
                      ? DashboardTokens.bermuda15
                      : DashboardTokens.apricot.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAffordable
                        ? DashboardTokens.bermuda
                        : DashboardTokens.apricot,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAffordable
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: isAffordable
                              ? DashboardTokens.bermuda
                              : DashboardTokens.apricot,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _result!.statusTitle,
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isAffordable
                                  ? DashboardTokens.bermuda
                                  : DashboardTokens.apricot,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result!.statusMessage,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: DashboardTokens.periwinkleGray,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cash after bills:',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_result!.cashAfterBills),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: DashboardTokens.periwinkleGray,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Post-purchase balance:',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format(_result!.postPurchaseBalance),
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: DashboardTokens.periwinkleGray,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}
