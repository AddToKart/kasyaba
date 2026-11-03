import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_tokens.dart';

/// Recessed label-left input row used by the financial forms.
class LabelRowField extends StatelessWidget {
  final String label;
  final Widget child;
  final double labelWidth;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const LabelRowField({
    super.key,
    required this.label,
    required this.child,
    this.labelWidth = 90,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget row = Padding(
      padding: padding,
      child: Row(
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                color: KasyabaTokens.periwinkleGraySubtitle,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );

    if (onTap != null) {
      row = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: row),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: KasyabaTokens.bigStone,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
        border: Border.all(color: KasyabaTokens.poloBlue22),
      ),
      clipBehavior: Clip.antiAlias,
      child: row,
    );
  }
}
