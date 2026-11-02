import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import 'dashboard_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasya Ba Today? Math Breakdown Sheet (Node 79:104)
/// ─────────────────────────────────────────────────────────────
void showSafeSpendBreakdownSheet(
  BuildContext context,
  DailySafeSpendCalculation calc,
) {
  final hasSafeSpend = calc.dailySafeSpend > 0;
  final accentColor =
      hasSafeSpend ? DashboardTokens.bermuda : DashboardTokens.apricot;
  final formattedPayday = DateFormat('MMMM d, yyyy').format(calc.nextPayday);
  final shortPayday = DateFormat('MMM d').format(calc.nextPayday);

  ModernBottomSheet.show(
    context: context,
    title: 'Kasya Ba Today? Math Breakdown',
    subtitle:
        '100% deterministic calculation of your safe daily spending allowance.',
    showDragHandle: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Formula Box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.functions_rounded,
                    size: 16,
                    color: DashboardTokens.bermuda,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'EXACT DETERMINISTIC FORMULA',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: DashboardTokens.bermuda,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: DashboardTokens.ebony.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DashboardTokens.poloBlue22),
                ),
                child: Text(
                  'Daily Safe Spend = Math.max(0, (Total Liquid Balance - Unpaid Bills Due Before Next Payday - Scheduled Goal Contributions) / Days Until Next Payday)',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: DashboardTokens.periwinkleGray,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'In simple words: (Available Cash Pool) ÷ (Days Left Until Payday)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Numerator Details (Cash Pool)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 15,
                    color: DashboardTokens.periwinkleGray,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'NUMERATOR (SAFE CASH BUFFER)',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Your Available Cash Pool (Cash minus commitments)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeterministicRow(
                label: 'Total Liquid Balance',
                value: CurrencyFormatter.format(calc.totalLiquidBalance),
                prefix: '+',
                valueColor: DashboardTokens.bermuda,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Unpaid Bills Due (before $shortPayday)',
                sublabel:
                    '${calc.unpaidBillsCount} unpaid bill${calc.unpaidBillsCount == 1 ? '' : 's'} due on or before payday',
                value: CurrencyFormatter.format(calc.unpaidBillsDue),
                prefix: '-',
                valueColor: calc.unpaidBillsDue > 0
                    ? DashboardTokens.apricot
                    : DashboardTokens.periwinkleGraySubtitle,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Scheduled Goal Contributions',
                sublabel:
                    '${calc.activeGoalsCount} active goal${calc.activeGoalsCount == 1 ? '' : 's'} prorated to next payday',
                value:
                    CurrencyFormatter.format(calc.scheduledGoalContributions),
                prefix: '-',
                valueColor: calc.scheduledGoalContributions > 0
                    ? DashboardTokens.poloBlue
                    : DashboardTokens.periwinkleGraySubtitle,
              ),
              if (calc.goalDetails.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DashboardTokens.ebony.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DashboardTokens.poloBlue22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GOAL PRORATION BREAKDOWN',
                        style: GoogleFonts.dmSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.6,
                          color: DashboardTokens.poloBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final detail in calc.goalDetails) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.track_changes_rounded,
                              size: 14,
                              color: DashboardTokens.bermuda,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    detail.title,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: DashboardTokens.periwinkleGray,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${CurrencyFormatter.format(detail.dailyRate)}/day × ${detail.daysCounted} days until payday',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 10.5,
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                      fontFeatures:
                                          CurrencyFormatter.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(detail.totalContribution)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.poloBlue,
                                fontFeatures:
                                    CurrencyFormatter.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                        if (detail != calc.goalDetails.last)
                          const Divider(
                            color: DashboardTokens.poloBlue22,
                            height: 12,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              const Divider(color: DashboardTokens.poloBlue22, height: 20),
              _buildDeterministicRow(
                label: 'Safe Available Cash',
                value: CurrencyFormatter.format(calc.numerator),
                prefix: '=',
                isTotal: true,
                valueColor: calc.numerator > 0
                    ? DashboardTokens.periwinkleGray
                    : DashboardTokens.apricot,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Denominator Details (Payday Timeline)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: DashboardTokens.poloBlue22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: DashboardTokens.poloBlue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DENOMINATOR (PAYDAY TIMELINE)',
                    style: GoogleFonts.dmSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: DashboardTokens.poloBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Days Until Next Payday (Cash stretch period)',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeterministicRow(
                label: 'Next Configured Payday',
                sublabel: 'Schedule: ${calc.paydaySchedule}',
                value: formattedPayday,
                valueColor: DashboardTokens.periwinkleGray,
              ),
              const SizedBox(height: 8),
              _buildDeterministicRow(
                label: 'Days Until Next Payday',
                value: '÷ ${calc.daysUntilPayday} days',
                valueColor: DashboardTokens.poloBlue,
                isTotal: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Result Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasSafeSpend
                      ? Icons.verified_rounded
                      : Icons.warning_amber_rounded,
                  color: accentColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAILY SAFE SPEND ALLOWANCE',
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.format(calc.dailySafeSpend),
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                            fontFeatures: CurrencyFormatter.tabularFigures,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ day',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contextual Explanation for ₱0.00
        if (!hasSafeSpend) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: DashboardTokens.bigStone,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: DashboardTokens.apricot.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: DashboardTokens.apricot,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        calc.totalLiquidBalance <= 0
                            ? 'Why is your daily safe spend ₱0.00?'
                            : 'Savings & Bills Protection Active',
                        style: GoogleFonts.dmSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: DashboardTokens.apricot,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  calc.totalLiquidBalance <= 0
                      ? 'You have ₱0.00 recorded in your balance right now, but your ${calc.activeGoalsCount > 0 ? "active goal requires ${CurrencyFormatter.format(calc.scheduledGoalContributions)}" : "upcoming bills require funding"} before your next payday ($shortPayday). Kasyaba holds your allowance at ₱0.00 so you don\'t overspend money you don\'t have yet.'
                      : 'Your upcoming bills (${CurrencyFormatter.format(calc.unpaidBillsDue)}) and goal contributions (${CurrencyFormatter.format(calc.scheduledGoalContributions)}) exceed your current cash. Kasyaba holds your daily spending at ₱0.00 to keep your essential commitments protected until payday.',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: DashboardTokens.periwinkleGraySubtitle,
                    height: 1.4,
                  ),
                ),
                if (calc.totalLiquidBalance <= 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go('/transactions/add', extra: 'income');
                      },
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: const Text(
                        '+ Log Starting Cash / Balance',
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DashboardTokens.bermuda,
                        side: const BorderSide(color: DashboardTokens.bermuda),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 18),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(
            backgroundColor: DashboardTokens.periwinkleGray,
            foregroundColor: DashboardTokens.ebony,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'Close Breakdown',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}

Widget _buildDeterministicRow({
  required String label,
  String? sublabel,
  required String value,
  String? prefix,
  bool isTotal = false,
  Color? valueColor,
}) {
  final effectiveColor = valueColor ?? DashboardTokens.periwinkleGray;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11.5,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal
                    ? DashboardTokens.periwinkleGray
                    : DashboardTokens.periwinkleGraySubtitle,
              ),
            ),
            if (sublabel != null) ...[
              const SizedBox(height: 1),
              Text(
                sublabel,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: DashboardTokens.periwinkleGraySubtitle
                      .withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(width: 8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (prefix != null) ...[
            Text(
              prefix,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: effectiveColor,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: isTotal ? 13 : 11.5,
              fontWeight: FontWeight.bold,
              color: effectiveColor,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
        ],
      ),
    ],
  );
}
