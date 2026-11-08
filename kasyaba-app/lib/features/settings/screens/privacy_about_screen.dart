import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../core/app_info.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/pill_button.dart';

/// Opens a hosted legal page in the platform browser. The in-app summary stays
/// readable offline; only this external action needs a connection.
Future<void> _openHostedUrl(BuildContext context, String url) async {
  var hasConnection = true;
  try {
    final results = await Connectivity().checkConnectivity();
    hasConnection = results.any((result) => result != ConnectivityResult.none);
  } catch (_) {
    // Connectivity is unavailable (e.g. widget tests) — attempt to open anyway.
  }

  if (!hasConnection) {
    if (context.mounted) {
      KasyabaToast.showError(
        context,
        'You are offline.',
        subtitle:
            'Reconnect to open the full hosted policy. The summary above still works offline.',
      );
    }
    return;
  }

  var opened = false;
  try {
    opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (_) {
    opened = false;
  }

  if (!opened && context.mounted) {
    KasyabaToast.showError(
      context,
      'Could not open the link.',
      subtitle: 'Check your connection and try again.',
    );
  }
}

/// ─────────────────────────────────────────────────────────────
///  Privacy and About Screen (1:1 Figma Node 42:6959)
/// ─────────────────────────────────────────────────────────────
class PrivacyAndAboutScreen extends StatelessWidget {
  const PrivacyAndAboutScreen({super.key});

  static void showTermsSheet(BuildContext context) {
    AppHaptics.selectionClick();
    showKasyabaSheet<void>(
      context: context,
      builder: (ctx) => AppSheet(
        color: context.kColors.canvas,
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
                color: context.kColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '1. Purpose: Kasyaba provides deterministic personal financial calculations (safe-to-spend, cash buffer, payday countdown, installment math).\n\n'
              '2. No Financial Advice: Kasyaba is a financial calculation and budgeting tool, not a registered investment or banking advisor.\n\n'
              '3. Data Ownership: You own 100% of your financial data. You may export or purge your records at any time without penalty.\n\n'
              '4. Online-first architecture: your ledger syncs to your private authenticated account; day-to-day math runs on-device for instant feedback; planning, health scoring, and forecast verdicts are computed on our server.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: context.kColors.textSecondary,
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
        color: context.kColors.canvas,
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
                color: context.kColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Zero AI & No Trackers: Kasyaba never shares or submits your numbers, salary, or account transactions to third-party AI models (OpenAI, Gemini, etc.) or ad networks.\n\n'
              '• Online-first + on-device math: Your ledger lives on our server. Daily safe-to-spend math, payday countdowns, statutory deductions, and simulator math run deterministically on your device for instant feedback. Planning, health scores, snapshots, and forecast verdicts are computed on our server.\n\n'
              '• Secure Sync & Backup: Your records are encrypted in transit (HTTPS/TLS) and sync to your private Kasyaba account so you can access your wallets across devices.\n\n'
              '• Data Privacy Act (RA 10173): We respect your privacy rights. We never track your activity, never profile your spending, and never sell your personal information.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: context.kColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This summary is available offline. The full hosted policy has the complete details.',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: context.kColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            PillButton(
              label: 'Read full policy',
              icon: Icons.open_in_new_rounded,
              onPressed: () => _openHostedUrl(ctx, kPrivacyPolicyUrl),
            ),
            const SizedBox(height: 10),
            PillButton(
              label: 'Terms',
              variant: PillButtonVariant.secondary,
              onPressed: () => _openHostedUrl(ctx, kTermsUrl),
            ),
            const SizedBox(height: 10),
            PillButton(
              label: 'Close',
              variant: PillButtonVariant.secondary,
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
      backgroundColor: context.kColors.canvas,
      body: Container(
        decoration: BoxDecoration(
          color: context.kColors.canvas,
          gradient: context.kColors.backgroundGradient,
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
                          color: context.kColors.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.kColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.chevron_left_rounded,
                            color: context.kColors.textPrimary,
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
                        color: context.kColors.textPrimary,
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
                    color: context.kColors.cardHero,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: context.kColors.cardBorderStrong,
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
                          color: context.kColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your ledger lives on our server. Day-to-day money math runs instantly on your device. Your data is never shared with third-party advertisers, trackers, or commercial AI models.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: context.kColors.textPrimary,
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
                      color: context.kColors.textPrimary,
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
                    color: context.kColors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: context.kColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildKeyValueRow(
                        context: context,
                        label: 'Your records',
                        value: 'Server-backed with offline cache',
                      ),
                      const SizedBox(height: 12),
                      _buildKeyValueRow(
                        context: context,
                        label: 'Calculations',
                        value: 'Daily math on-device; planning & forecasts on server',
                      ),
                      const SizedBox(height: 12),
                      _buildKeyValueRow(
                        context: context,
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
                      color: context.kColors.textPrimary,
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
                    color: context.kColors.card,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: context.kColors.cardBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Image.asset(
                              'assets/images/brand/kasyaba_mark.png',
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Kasyaba',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: context.kColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildDivider(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: _buildKeyValueRow(
                          context: context,
                          label: 'Version',
                          value: kAppVersionLabel,
                        ),
                      ),
                      _buildDivider(context),
                      _buildActionRow(
                        context: context,
                        title: 'Terms of service',
                        actionText: 'Read',
                        onTap: () => showTermsSheet(context),
                      ),
                      _buildDivider(context),
                      _buildActionRow(
                        context: context,
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
    required BuildContext context,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: context.kColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.kColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow({
    required BuildContext context,
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
                color: context.kColors.textPrimary,
              ),
            ),
            Text(
              actionText,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: context.kColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 1,
      color: context.kColors.divider,
    );
  }
}
