import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../shared/widgets/kasyaba_background.dart';

/// Shown while the stored session is being restored so authenticated users
/// never see a flash of the login screen on cold start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: KasyabaBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.canvas,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.cardBorder),
                ),
                child: Image.asset(
                  'assets/images/brand/kasyaba_mark.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'KASYABA',
                style: GoogleFonts.bricolageGrotesque(
                  color: colors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: colors.primaryButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
