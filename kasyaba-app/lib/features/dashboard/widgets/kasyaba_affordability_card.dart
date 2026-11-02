import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_tokens.dart';

class KasyaBaAffordabilityCard extends StatelessWidget {
  final VoidCallback onTap;

  const KasyaBaAffordabilityCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: DashboardTokens.periwinkleGray,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'KasyaBa?',
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.ebony,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Test a purchase if you can afford it.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: DashboardTokens.cello,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: DashboardTokens.ebony,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/images/dashboard_arrow_right.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  DashboardTokens.periwinkleGray,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

