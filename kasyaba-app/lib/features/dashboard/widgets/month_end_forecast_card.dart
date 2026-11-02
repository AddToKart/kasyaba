import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dashboard_tokens.dart';

class MonthEndForecastCard extends StatelessWidget {
  final DashboardData data;
  final VoidCallback? onTap;

  const MonthEndForecastCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final monthEndStr = DateFormat('MMM d').format(monthEnd);
    final monthStartStr = DateFormat('MMM 1').format(now);

    final isPositive = data.predictedMonthEnd >= 0;
    final badgeText = isPositive ? 'Bills covered' : 'Review bills';
    final badgeTextColor = isPositive ? DashboardTokens.bermuda : DashboardTokens.apricot;
    final badgeBgColor = isPositive ? DashboardTokens.bermuda15 : DashboardTokens.apricot.withValues(alpha: 0.15);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "Month-end forecast" (Bricolage Grotesque/Bold 19 #C9DCEA)
        Text(
          'Month-end forecast',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: DashboardTokens.periwinkleGray,
          ),
        ),
        const SizedBox(height: 10),

        // Main Card (fill: #16293F, stroke: Polo Blue 22%, r=28, padding: 19)
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(19),
            decoration: BoxDecoration(
              color: DashboardTokens.bigStone,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: DashboardTokens.poloBlue22,
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.format(data.predictedMonthEnd),
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: DashboardTokens.periwinkleGray,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Projected balance on $monthEndStr',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge: "Bills covered"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Chart Area
                SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SvgPicture.asset(
                      'assets/images/dashboard_forecast_chart.svg',
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Timeline Markers (Oct 1, Today, Oct 31)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthStartStr,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    Text(
                      'Today',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    Text(
                      monthEndStr,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Legend Row
                Row(
                  children: [
                    // Actual (Solid Periwinkle Gray)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: DashboardTokens.periwinkleGray,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Actual',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Projected (Dashed Polo Blue)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(
                          size: const Size(16, 3),
                          painter: _DashedLinePainter(
                            color: DashboardTokens.poloBlue,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Projected',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Bill due (Apricot Dot)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: DashboardTokens.apricot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bill due',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: DashboardTokens.periwinkleGraySubtitle,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.height
      ..style = PaintingStyle.stroke;

    const dashWidth = 3.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset((startX + dashWidth).clamp(0, size.width), size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

