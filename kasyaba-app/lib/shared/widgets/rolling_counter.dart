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
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        if (widget.prefix != null)
          Text(
            widget.prefix!,
            style: effectiveStyle,
          ),
        for (int i = 0; i < characters.length; i++)
          _CharacterSlot(
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
    required this.char,
    required this.style,
    required this.duration,
    required this.curve,
    required this.staggerIndex,
  });

  @override
  Widget build(BuildContext context) {
    final digit = int.tryParse(char);

    // Non-digit characters (, . - •) don't roll; they render statically
    if (digit == null) {
      return AnimatedSwitcher(
        duration: AppMotion.snappy,
        child: Text(
          char,
          key: ValueKey(char),
          style: style,
        ),
      );
    }

    // Digit column: 0 to 9 in a vertical strip
    return _DigitColumn(
      targetDigit: digit,
      style: style,
      duration: duration + Duration(milliseconds: staggerIndex * 25),
      curve: curve,
    );
  }
}

class _DigitColumn extends StatefulWidget {
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
  State<_DigitColumn> createState() => _DigitColumnState();
}

class _DigitColumnState extends State<_DigitColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  late int _currentDigit;

  @override
  void initState() {
    super.initState();
    _currentDigit = widget.targetDigit;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = AlwaysStoppedAnimation<double>(_currentDigit.toDouble());
  }

  @override
  void didUpdateWidget(_DigitColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetDigit != widget.targetDigit) {
      final start = _animation.value;
      final end = widget.targetDigit.toDouble();
      _controller.duration = widget.duration;
      _animation = Tween<double>(begin: start, end: end).animate(
        CurvedAnimation(
          parent: _controller,
          curve: widget.curve,
        ),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hidden '0' sets the exact intrinsic width and height to match the TextStyle
    return ClipRect(
      child: Stack(
        children: [
          Opacity(
            opacity: 0.0,
            child: Text('0', style: widget.style),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final digitHeight = constraints.maxHeight;
                return AnimatedBuilder(
                  animation: _animation,
                  builder: (context, _) {
                    final yOffset = -_animation.value * digitHeight;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: yOffset,
                          left: 0,
                          right: 0,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int d = 0; d <= 9; d++)
                                SizedBox(
                                  height: digitHeight,
                                  child: Center(
                                    child: Text(
                                      '$d',
                                      style: widget.style,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

