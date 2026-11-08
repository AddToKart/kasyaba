import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';

class DashboardHeader extends StatelessWidget {
  final String displayName;
  final VoidCallback onNotificationsTap;

  const DashboardHeader({
    super.key,
    required this.displayName,
    required this.onNotificationsTap,
  });

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    final firstName = displayName.trim().isEmpty
        ? 'User'
        : displayName.trim().split(' ').first;
    final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

    return Row(
      children: [
        // Avatar Ring (48x48, r=24, fill: #C9DCEA)
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryButton,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: GoogleFonts.bricolageGrotesque(
              color: colors.onPrimaryButton,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting & Name
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _greeting(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                firstName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),

        // Notification Button (50x50, r=24, fill: #16293F, border: Polo Blue 22%)
        GestureDetector(
          onTap: onNotificationsTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.cardBorder, width: 1.0),
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                colors.textSecondary,
                BlendMode.srcIn,
              ),
              child: SvgPicture.asset(
                'assets/images/dashboard_bell.svg',
                width: 22,
                height: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
