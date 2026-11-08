import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../shared/widgets/motion_components.dart';

class KasyaBaAffordabilityCard extends StatelessWidget {
  final VoidCallback onTap;

  const KasyaBaAffordabilityCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    return SpringTouch(
      scaleDown: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: colors.primaryButton,
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
                      color: colors.onPrimaryButton,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Test a purchase if you can afford it.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: colors.cardHero,
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
              decoration: BoxDecoration(
                color: colors.onPrimaryButton,
                shape: BoxShape.circle,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  colors.textPrimary,
                  BlendMode.srcIn,
                ),
                child: SvgPicture.asset(
                  'assets/images/dashboard_arrow_right.svg',
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
