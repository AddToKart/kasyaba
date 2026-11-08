import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_color_scheme.dart';
import '../../app/theme/kasyaba_tokens.dart';
import 'pill_button.dart';

/// Tokenized empty state with an optional action.
class KasyabaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const KasyabaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.card,
                shape: BoxShape.circle,
                border: Border.all(color: colors.cardBorder),
              ),
              child: Icon(
                icon,
                size: 30,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared failure card — never masquerade a failed request as an empty state.
class KasyabaErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  const KasyabaErrorCard({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
        border: Border.all(
          color: colors.danger.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 22,
                color: colors.danger,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.dmSans(
                    fontSize: 13.5,
                    height: 1.4,
                    color: colors.danger,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: PillButton(
                label: retryLabel,
                onPressed: onRetry,
                variant: PillButtonVariant.destructive,
                height: 44,
                expand: false,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dependency-free shimmer-less skeleton blocks using token surfaces.
class KasyabaLoadingSkeleton extends StatelessWidget {
  final int lines;

  const KasyabaLoadingSkeleton({super.key, this.lines = 3});

  @override
  Widget build(BuildContext context) {
    final colors = context.kColors;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.skeletonFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < lines; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == lines - 1 ? 0 : 10),
              child: FractionallySizedBox(
                widthFactor: i == 0 ? 1.0 : (i.isOdd ? 0.8 : 0.6),
                child: Container(
                  height: i == 0 ? 18 : 12,
                  decoration: BoxDecoration(
                    color: colors.icon.withValues(
                      alpha: 0.12 + (i % 3) * 0.04,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
