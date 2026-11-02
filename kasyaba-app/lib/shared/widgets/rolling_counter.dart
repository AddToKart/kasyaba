import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme/app_motion.dart';

/// ─────────────────────────────────────────────────────────────
///  RollingCounter — Mechanical Flip Ticker Digit Widget
///  Rolls numbers vertically like an odometer wheel with spring physics.
/// ─────────────────────────────────────────────────────────────

class RollingCounter extends StatefulWidget {
  final num value;
  final TextStyle? style;
  final String? prefix;
  final String? suffix;
  final int fractionDigits;
  final bool isPrivacyMode;
  final Duration duration;
  final Curve curve;

  const RollingCounter({
    super.key,
    required this.value,
    this.style,
    this.prefix,
    this.suffix,
    this.fractionDigits = 2,
    this.isPrivacyMode = false,
    this.duration = AppMotion.expressive,
    this.curve = AppMotion.springRecoil,
  });

  @override
  State<RollingCounter> createState() => _RollingCounterState();
}

class _RollingCounterState extends State<RollingCounter> {
  late NumberFormat _formatter;

  @override
  void initState() {
    super.initState();
    _updateFormatter();
  }

  @override
  void didUpdateWidget(RollingCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fractionDigits != widget.fractionDigits) {
      _updateFormatter();
    }
  }

  void _updateFormatter() {
    _formatter = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '',
      decimalDigits: widget.fractionDigits,
    );
  }

  String _formatValue() {
    if (widget.isPrivacyMode) {
      return '•••••••';
    }
    return _formatter.format(widget.value).trim();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = (widget.style ?? DefaultTextStyle.of(context).style).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final formattedText = _formatValue();
    final characters = formattedText.split('');

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.prefix != null)
          Text(
            widget.prefix!,
            style: effectiveStyle,
          ),
        for (int i = 0; i < characters.length; i++)
          _CharacterSlot(
            key: ValueKey('slot_${i}_${characters.length}'),
            char: characters[i],
            style: effectiveStyle,
            duration: widget.duration,
            curve: widget.curve,
            staggerIndex: i,
          ),
        if (widget.suffix != null)
          Text(
            widget.suffix!,
            style: effectiveStyle,
          ),
      ],
    );
  }
}

class _CharacterSlot extends StatelessWidget {
  final String char;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final int staggerIndex;

  const _CharacterSlot({
    super.key,
    required this.char,
    required this.style,
    required this.duration,
    required this.curve,
    required this.staggerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final digit = int.tryParse(char);

    // Non-digit characters (, . - •) render statically or with fade
    if (digit == null) {
      return Text(
        char,
        key: ValueKey(char),
        style: style,
      );
    }

    // Digit column: animated vertical transition per digit
    return _DigitColumn(
      targetDigit: digit,
      style: style,
      duration: duration + Duration(milliseconds: staggerIndex * 20),
      curve: curve,
    );
  }
}

class _DigitColumn extends StatelessWidget {
  final int targetDigit;
  final TextStyle style;
  final Duration duration;
  final Curve curve;

  const _DigitColumn({
    required this.targetDigit,
    required this.style,
    required this.duration,
    required this.curve,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (child, animation) {
        return ClipRect(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.4),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        '$targetDigit',
        key: ValueKey<int>(targetDigit),
        style: style,
      ),
    );
  }
}

