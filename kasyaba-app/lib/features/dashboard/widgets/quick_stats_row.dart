import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dashboard_tokens.dart';

class QuickStatsRow extends StatelessWidget {
  final double savings;
  final double budgetPercent;

  /// Null means the runway cannot be derived (e.g. no spending history yet).
  final int? runwayDays;
  final VoidCallback onSavedTap;
  final VoidCallback onBudgetTap;
  final VoidCallback onBufferTap;

  const QuickStatsRow({
    super.key,
    required this.savings,
    required this.budgetPercent,
    required this.runwayDays,
    required this.onSavedTap,
    required this.onBudgetTap,
    required this.onBufferTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedSaved = CurrencyFormatter.formatCompact(savings);
    final formattedBudget = '${budgetPercent.toStringAsFixed(0)}%';
    final days = runwayDays;
    final formattedBuffer = days == null
        ? '—'
        : (days >= 90 ? '90+ days' : '$days days');
    final bufferColor = days == null
        ? DashboardTokens.periwinkleGraySubtitle
        : DashboardTokens.bermuda;

    final budgetColor = budgetPercent >= 100
        ? DashboardTokens.apricot
        : (budgetPercent >= 80
              ? DashboardTokens.apricot.withValues(alpha: 0.9)
              : DashboardTokens.bermuda);

    return Row(
      children: [
        // Card 1: Saved
        Expanded(
          child: _QuickStatCard(
            value: formattedSaved,
            label: 'Saved',
            valueColor: DashboardTokens.periwinkleGray,
            onTap: onSavedTap,
          ),
        ),
        const SizedBox(width: 10),

        // Card 2: Budget used
        Expanded(
          child: _QuickStatCard(
            value: formattedBudget,
            label: 'Budget used',
            valueColor: budgetColor,
            onTap: onBudgetTap,
          ),
        ),
        const SizedBox(width: 10),

        // Card 3: Buffer
        Expanded(
          child: _QuickStatCard(
            value: formattedBuffer,
            label: 'Buffer',
            valueColor: bufferColor,
            onTap: onBufferTap,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;
  final VoidCallback onTap;

  const _QuickStatCard({
    required this.value,
    required this.label,
    required this.valueColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTouch(
      scaleDown: 0.94,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
        decoration: BoxDecoration(
          color: DashboardTokens.bigStone,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: DashboardTokens.poloBlue22, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: valueColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: DashboardTokens.periwinkleGraySubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
