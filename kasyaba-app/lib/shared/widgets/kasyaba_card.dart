import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/kasyaba_tokens.dart';

enum KasyabaCardVariant { standard, hero, flat }

/// Tokenized card surface: standard, frosted hero, or borderless flat.
class KasyabaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final KasyabaCardVariant variant;
  final double radius;
  final Color? borderColor;
  final bool blur;
  final VoidCallback? onTap;

  const KasyabaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.variant = KasyabaCardVariant.standard,
    this.radius = KasyabaTokens.radiusCard,
    this.borderColor,
    this.blur = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFlat = variant == KasyabaCardVariant.flat;
    final isHero = variant == KasyabaCardVariant.hero;

    final Color fill = isFlat
        ? Colors.transparent
        : (isHero ? KasyabaTokens.cello60 : KasyabaTokens.bigStone);
    final Color? effectiveBorder = isFlat
        ? null
        : (borderColor ??
            (isHero ? KasyabaTokens.poloBlue30 : KasyabaTokens.poloBlue22));

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: content),
      );
    }

    Widget card = Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: effectiveBorder == null
            ? null
            : Border.all(color: effectiveBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );

    if (blur) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: card,
        ),
      );
    }

    return card;
  }
}
