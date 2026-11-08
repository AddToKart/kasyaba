import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';

class HeroSafeSpendCard extends StatelessWidget {
  final double totalBalance;
  final DailySafeSpendCalculation safeSpendCalc;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onTapBreakdown;

  const HeroSafeSpendCard({
    super.key,
    required this.totalBalance,
    required this.safeSpendCalc,
    required this.isVisible,
    required this.onToggleVisibility,
    required this.onExpense,
    required this.onIncome,
    required this.onTapBreakdown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    final formattedDaily = isVisible
        ? CurrencyFormatter.format(safeSpendCalc.dailySafeSpend)
        : '₱ ••••••';
    final formattedTotal = isVisible
        ? CurrencyFormatter.format(totalBalance)
        : '₱ ••••••';
    final formattedPayday = DateFormat(
      'MMM d',
    ).format(safeSpendCalc.nextPayday);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          padding: const EdgeInsets.all(21),
          decoration: BoxDecoration(
            color: colors.cardHero,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.cardBorderStrong, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Label & Eye visibility toggle & Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.successTint,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.success.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'KASYA BA TODAY?',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                            color: colors.success,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DAILY SAFE SPEND',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Breakdown link
                      GestureDetector(
                        onTap: onTapBreakdown,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.card,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.cardBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Breakdown',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.info_outline_rounded,
                                size: 12,
                                color: colors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Eye Toggle (19x19, r=15)
                  SpringTouch(
                    scaleDown: 0.85,
                    onTap: onToggleVisibility,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          colors.textSecondary,
                          BlendMode.srcIn,
                        ),
                        child: SvgPicture.asset(
                          'assets/images/dashboard_eye.svg',
                          width: 19,
                          height: 19,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Daily Safe Spend Amount Row
              SpringTouch(
                scaleDown: 0.98,
                onTap: onTapBreakdown,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          formattedDaily,
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            height: 1.05,
                            color: colors.textPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ' / day',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Subtext: For the next X days, until [date] payday
              Text(
                'For the next ${safeSpendCalc.daysUntilPayday} days, until $formattedPayday payday',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),

              // 1px Divider (Polo Blue 22%)
              Container(height: 1, color: colors.cardBorder),
              const SizedBox(height: 12),

              // Total balance row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    'Total balance',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: colors.textSecondary,
                    ),
                  ),
                  Text(
                    formattedTotal,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Actions Row (ONLY Expense and Income - strictly no transfer)
              Row(
                children: [
                  // Button 1: Expense (border: Kashmir Blue, height: 54, r=27)
                  Expanded(
                    child: SpringTouch(
                      scaleDown: 0.94,
                      onTap: onExpense,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(
                            color: colors.secondaryBorder,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                colors.textPrimary,
                                BlendMode.srcIn,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/dashboard_minus.svg',
                                width: 18,
                                height: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Expense',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Button 2: Income (fill: Periwinkle Gray, height: 54, r=27, text: Ebony)
                  Expanded(
                    child: SpringTouch(
                      scaleDown: 0.94,
                      onTap: onIncome,
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: colors.primaryButton,
                          borderRadius: BorderRadius.circular(27),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                colors.onPrimaryButton,
                                BlendMode.srcIn,
                              ),
                              child: SvgPicture.asset(
                                'assets/images/dashboard_plus.svg',
                                width: 18,
                                height: 18,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Income',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colors.onPrimaryButton,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
