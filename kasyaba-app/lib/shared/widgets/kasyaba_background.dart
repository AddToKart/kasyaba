import 'package:flutter/material.dart';

import '../../app/theme/kasyaba_tokens.dart';

/// Full-canvas navy background with the canonical radial glow.
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
        gradient: gradient ?? KasyabaTokens.canvasGradient,
      ),
      child: child,
    );
  }
}
