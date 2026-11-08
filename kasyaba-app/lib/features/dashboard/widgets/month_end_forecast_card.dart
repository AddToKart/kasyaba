import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';

class MonthEndForecastCard extends ConsumerWidget {
  final DashboardData data;
  final VoidCallback? onTap;

  const MonthEndForecastCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.kColors;
    final now = DateTime.now();
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final monthEndStr = DateFormat('MMM d').format(monthEnd);
    final monthStartStr = DateFormat('MMM 1').format(now);

    final billsAsync = ref.watch(billsProvider);
    final bills = billsAsync.valueOrNull;
    final todayStart = DateTime(now.year, now.month, now.day);

    double upcomingBillsTotal = 0.0;
    if (bills != null) {
      for (final bill in bills) {
        if (bill.status == 'paid') continue;
        if (bill.dueDate.isBefore(todayStart)) continue;
        upcomingBillsTotal += bill.amount;
      }
    }

    final bool isPositive;
    final String badgeText;
    if (bills == null) {
      // Bills data is still loading or failed: never claim bills are covered.
      isPositive = data.predictedMonthEnd >= 0;
      badgeText = isPositive ? 'Projected positive' : 'Tight month';
    } else if (upcomingBillsTotal > 0) {
      isPositive = data.predictedMonthEnd >= upcomingBillsTotal;
      badgeText = isPositive ? 'Bills covered' : 'Tight month';
    } else {
      isPositive = data.predictedMonthEnd >= 0;
      badgeText = isPositive ? 'Projected positive' : 'Tight month';
    }

    final badgeTextColor = isPositive ? colors.success : colors.danger;
    final badgeBgColor = isPositive ? colors.successTint : colors.dangerTint;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "Month-end forecast" (Bricolage Grotesque/Bold 19 #C9DCEA)
        Text(
          'Month-end forecast',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
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
              color: colors.card,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.cardBorder, width: 1.0),
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
                                color: colors.textPrimary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Projected balance on $monthEndStr',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge: only claims bills are covered when we know they are.
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

                // Live chart sourced from DashboardData.dailyBalance
                SizedBox(
                  height: 132,
                  width: double.infinity,
                  child: _ForecastChart(points: data.dailyBalance),
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
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      'Today',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.textPrimary,
                      ),
                    ),
                    Text(
                      monthEndStr,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: colors.textSecondary,
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
                            color: colors.textPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Actual',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: colors.textSecondary,
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
                          painter: _DashedLinePainter(color: colors.icon),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Projected',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: colors.textSecondary,
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
                          decoration: BoxDecoration(
                            color: colors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bill due',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.normal,
                            color: colors.textSecondary,
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

/// Renders actual vs projected daily balances. Never falls back to the static
/// Figma asset: if no daily balance data exists, a neutral placeholder renders.
class _ForecastChart extends StatelessWidget {
  final List<DailyBalancePoint> points;

  const _ForecastChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    if (points.isEmpty) {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.canvas.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        child: Text(
          'Forecast chart will appear once daily balances are available.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
      );
    }

    final sorted = List<DailyBalancePoint>.from(points);
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(a.date);
      final dateB = DateTime.tryParse(b.date);
      if (dateA == null || dateB == null) return 0;
      return dateA.compareTo(dateB);
    });

    final actualSpots = <FlSpot>[];
    final projectedSpots = <FlSpot>[];
    final values = <double>[];
    for (var i = 0; i < sorted.length; i++) {
      final point = sorted[i];
      final actual = point.balance;
      final projected = point.projected ?? point.balance;
      actualSpots.add(FlSpot(i.toDouble(), actual));
      projectedSpots.add(FlSpot(i.toDouble(), projected));
      values
        ..add(actual)
        ..add(projected);
    }

    final rawMin = values.reduce((a, b) => a < b ? a : b);
    final rawMax = values.reduce((a, b) => a > b ? a : b);
    final span = rawMax - rawMin;
    final padding = span.abs() < 1 ? 1.0 : span * 0.12;
    final minY = rawMin - padding;
    final maxY = rawMax + padding;
    final yInterval = (maxY - minY) / 2;
    final bottomInterval = sorted.length <= 2
        ? 1.0
        : ((sorted.length - 1) / 2).clamp(1.0, double.infinity).toDouble();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sorted.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: yInterval,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: colors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: yInterval,
              getTitlesWidget: (value, meta) => Text(
                CurrencyFormatter.formatCompact(value),
                style: GoogleFonts.dmSans(
                  fontSize: 9.5,
                  color: colors.textMuted,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: sorted.length > 1,
              reservedSize: 20,
              interval: bottomInterval,
              getTitlesWidget: (value, meta) {
                final index = value.round();
                if (index < 0 || index >= sorted.length) {
                  return const SizedBox.shrink();
                }
                final date = DateTime.tryParse(sorted[index].date);
                if (date == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('MMM d').format(date),
                    style: GoogleFonts.dmSans(
                      fontSize: 9.5,
                      color: colors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: actualSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: colors.textPrimary,
            barWidth: 2.4,
            isStrokeCapRound: true,
            dotData: FlDotData(show: sorted.length == 1),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: projectedSpots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: colors.icon.withValues(alpha: 0.4),
            barWidth: 2.0,
            isStrokeCapRound: true,
            dashArray: const [6, 4],
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
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
