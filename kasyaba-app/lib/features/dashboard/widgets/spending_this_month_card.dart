import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';

class SpendingThisMonthCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onTap;

  const SpendingThisMonthCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    final segmentColors = [
      colors.textPrimary,
      colors.icon,
      colors.secondaryBorder,
      colors.textMuted,
    ];
    final categories = data.categoryExpenses;
    final totalSpent = categories.fold<double>(
      0.0,
      (sum, cat) => sum + cat.total,
    );
    final displaySpent = totalSpent > 0
        ? totalSpent
        : (data.expenses).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "Spending this month"
        Text(
          'Spending this month',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // Main Card
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.cardBorder, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row: Amount + Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      CurrencyFormatter.format(displaySpent),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      ' spent this month',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Multi-segment progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 14,
                    child: categories.isEmpty || totalSpent <= 0
                        ? Container(
                            color: colors.secondaryBorder.withValues(
                              alpha: 0.3,
                            ),
                          )
                        : Row(
                            children: [
                              for (
                                int i = 0;
                                i < categories.length && i < 4;
                                i++
                              ) ...[
                                Expanded(
                                  flex: (categories[i].total * 1000)
                                      .toInt()
                                      .clamp(1, 1000000),
                                  child: Container(
                                    color:
                                        segmentColors[i % segmentColors.length],
                                  ),
                                ),
                                if (i < categories.length - 1 && i < 3)
                                  const SizedBox(width: 3),
                              ],
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Category Breakdown Rows
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No recorded category expenses yet this month.',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: colors.textSecondary,
                      ),
                    ),
                  )
                else
                  for (int i = 0; i < categories.length && i < 4; i++) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: segmentColors[i % segmentColors.length],
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              categories[i].categoryName,
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.normal,
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            CurrencyFormatter.format(categories[i].total),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.textPrimary,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
