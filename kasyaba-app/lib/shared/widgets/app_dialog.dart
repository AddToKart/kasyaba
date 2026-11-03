import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      final Color confirmForeground = KasyabaTokens.ebony;
      final Color confirmBackground = destructive
          ? KasyabaTokens.apricot
          : KasyabaTokens.periwinkleGray;

      return AlertDialog(
        backgroundColor: KasyabaTokens.bigStone,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
          side: const BorderSide(color: KasyabaTokens.poloBlue22),
        ),
        title: Text(
          title,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KasyabaTokens.periwinkleGray,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.45,
            color: KasyabaTokens.periwinkleGraySubtitle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: KasyabaTokens.periwinkleGraySubtitle,
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
