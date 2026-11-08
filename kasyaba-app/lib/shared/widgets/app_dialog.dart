import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_color_scheme.dart';
import '../../app/theme/kasyaba_tokens.dart';

Future<bool?> showKasyabaConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) {
      final colors = ctx.kColors;
      final Color confirmForeground = colors.onPrimaryButton;
      final Color confirmBackground =
          destructive ? colors.danger : colors.primaryButton;

      return AlertDialog(
        backgroundColor: colors.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
          side: BorderSide(color: colors.cardBorder),
        ),
        title: Text(
          title,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.45,
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
            ),
            child: Text(
              cancelLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: confirmBackground,
              foregroundColor: confirmForeground,
            ),
            child: Text(
              confirmLabel,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}
