import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/pill_button.dart';

/// ─────────────────────────────────────────────────────────────
///  Privacy and About Screen (1:1 Figma Node 42:6959)
/// ─────────────────────────────────────────────────────────────
class PrivacyAndAboutScreen extends StatelessWidget {
  const PrivacyAndAboutScreen({super.key});

  static const String kAppVersion = '0.1.0 (Build 1)';

  static void showTermsSheet(BuildContext context) {
    AppHaptics.selectionClick();
    showKasyabaSheet<void>(
      context: context,
      builder: (ctx) => AppSheet(
        color: DashboardTokens.ebony,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Terms of Service',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '1. Purpose: Kasyaba provides deterministic personal financial calculations (safe-to-spend, cash buffer, payday countdown, installment math).\n\n'
              '2. No Financial Advice: Kasyaba is a financial calculation and budgeting tool, not a registered investment or banking advisor.\n\n'
              '3. Data Ownership: You own 100% of your financial data. You may export or purge your records at any time without penalty.\n\n'
              '4. Hybrid Architecture: All daily math runs locally on your device. Your financial ledger syncs to your private authenticated account for cross-device access and backup.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: DashboardTokens.periwinkleGraySubtitle,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  static void showPrivacyPolicySheet(BuildContext context) {
    AppHaptics.selectionClick();
    showKasyabaSheet<void>(
      context: context,
      builder: (ctx) => AppSheet(
        color: DashboardTokens.ebony,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Privacy Policy',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Zero AI & No Trackers: Kasyaba never shares or submits your numbers, salary, or account transactions to third-party AI models (OpenAI, Gemini, etc.) or ad networks.\n\n'
              '• Local-First Edge Engine: All daily safe-to-spend math, payday countdowns, and tax deductions run deterministically right on your device.\n\n'
              '• Secure Sync & Backup: When connected, your records sync to your private Kasyaba backend account using encrypted sessions (TLS 1.3 & AES-256) so you can access your wallets across devices.\n\n'
              '• Data Privacy Act (RA 10173): We respect your privacy rights. We never track your activity, never profile your spending, and never sell your personal information.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: DashboardTokens.periwinkleGraySubtitle,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            PillButton(
              label: 'Close',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(
          color: DashboardTokens.ebony,
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, DashboardTokens.dockClearance),
            children: [
              // Header: 50x50 Squircle Back + Title (Figma Node 11:1062)
              FadeSlideEntrance.staggered(
                index: 0,
                child: Row(
                  children: [
                    SpringTouch(
                      onTap: () {
                        AppHaptics.lightImpact();
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/settings');
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: DashboardTokens.periwinkleGray,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Privacy and about',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hero Card: Your numbers stay yours (Figma Node 11:1068)
              FadeSlideEntrance.staggered(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: DashboardTokens.cello60,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue30,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your numbers stay yours',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: DashboardTokens.periwinkleGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Every calculation runs on your device. Your data is never shared with third-party advertisers, trackers, or commercial AI models.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: DashboardTokens.periwinkleGray,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section 1 Header: What we keep (Figma Node 11:1075)
              FadeSlideEntrance.staggered(
                index: 2,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text(
                    'What we keep',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
              ),

              // Section 1 Card (Figma Node 11:1076)
              FadeSlideEntrance.staggered(
                index: 3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 13),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildKeyValueRow(
                        label: 'Your records',
                        value: 'Local-first & private sync',
                      ),
                      const SizedBox(height: 12),
                      _buildKeyValueRow(
                        label: 'Calculations',
                        value: '100% on-device math',
                      ),
                      const SizedBox(height: 12),
                      _buildKeyValueRow(
                        label: 'AI',
                        value: 'None (100% deterministic)',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section 2 Header: About (Figma Node 11:1094)
              FadeSlideEntrance.staggered(
                index: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text(
                    'About',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
              ),

              // Section 2 Card (Figma Node 11:1095)
              FadeSlideEntrance.staggered(
                index: 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 6),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _buildKeyValueRow(
                          label: 'Version',
                          value: kAppVersion,
                        ),
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        title: 'Terms of service',
                        actionText: 'Read',
                        onTap: () => showTermsSheet(context),
                      ),
                      _buildDivider(),
                      _buildActionRow(
                        title: 'Privacy policy',
                        actionText: 'Read',
                        onTap: () => showPrivacyPolicySheet(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyValueRow({
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: DashboardTokens.periwinkleGraySubtitle,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: DashboardTokens.periwinkleGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required String title,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return SpringTouch(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            Text(
              actionText,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: DashboardTokens.periwinkleGraySubtitle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: DashboardTokens.poloBlue16,
    );
  }
}
