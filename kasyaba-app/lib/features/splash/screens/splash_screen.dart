import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/kasyaba_tokens.dart';
import '../../../shared/widgets/kasyaba_background.dart';

/// Shown while the stored session is being restored so authenticated users
/// never see a flash of the login screen on cold start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KasyabaTokens.ebony,
      body: KasyabaBackground(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: KasyabaTokens.periwinkleGray.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: KasyabaTokens.poloBlue22),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: KasyabaTokens.periwinkleGray,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'KASYABA',
                style: GoogleFonts.bricolageGrotesque(
                  color: KasyabaTokens.periwinkleGray,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: KasyabaTokens.periwinkleGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
