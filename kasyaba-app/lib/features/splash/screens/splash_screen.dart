import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Shown while the stored session is being restored so authenticated users
/// never see a flash of the login screen on cold start.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.emerald500,
              size: 44,
            ),
            SizedBox(height: 16),
            Text(
              'KASYABA',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.emerald500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
