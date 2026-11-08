import 'package:flutter/material.dart';

import '../../app/theme/kasyaba_color_scheme.dart';

/// Full-canvas background with the canonical per-theme radial glow.
class KasyabaBackground extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;

  const KasyabaBackground({
    super.key,
    required this.child,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? context.kColors.backgroundGradient,
      ),
      child: child,
    );
  }
}
