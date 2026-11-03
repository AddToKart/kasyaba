import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_motion.dart';
import '../../core/utils/currency_formatter.dart';

/// ─────────────────────────────────────────────────────────────
///  Kasyaba Motion Suite — Choreographed Kinematics
/// ─────────────────────────────────────────────────────────────

/// Smooth fade and slide entrance animation for cards, list items, and sections.
class FadeSlideEntrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;
  final Curve curve;

  const FadeSlideEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 280),
    this.slideOffset = const Offset(0, 0.06), // gentle 6% slide up
    this.curve = Curves.easeOutCubic,
  });

  /// Factory helper for staggered list items based on item index
  factory FadeSlideEntrance.staggered({
    Key? key,
    required int index,
    required Widget child,
    Duration baseDelay = Duration.zero,
    Duration stepDelay = const Duration(milliseconds: 35),
    Duration maxDelay = const Duration(milliseconds: 210),
  }) {
    final computedDelay = stepDelay * index;
    final cappedDelay = computedDelay > maxDelay ? maxDelay : computedDelay;
    return FadeSlideEntrance(
      key: key,
      delay: baseDelay + cappedDelay,
      child: child,
    );
  }

  @override
  State<FadeSlideEntrance> createState() => _FadeSlideEntranceState();
}

class _FadeSlideEntranceState extends State<FadeSlideEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(curved);

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}

/// Tactile spring-physics wrapper for buttons, chips, and cards.
/// Compresses slightly on press and springs back with a subtle haptic click.
class SpringTouch extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final bool enableHaptics;
  final HitTestBehavior behavior;

  const SpringTouch({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.95,
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<SpringTouch> createState() => _SpringTouchState();
}

class _SpringTouchState extends State<SpringTouch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.touchDown,
      reverseDuration: AppMotion.snappy,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutQuad,
        reverseCurve: AppMotion.springRecoil,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _isDown = true;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isDown) return;
    _isDown = false;
    _controller.reverse();
    if (widget.enableHaptics) {
      AppHaptics.lightImpact();
    }
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!_isDown) return;
    _isDown = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null) {
      return widget.child;
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress != null
          ? () {
              if (widget.enableHaptics) {
                AppHaptics.mediumImpact();
              }
              widget.onLongPress?.call();
            }
          : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Smooth counting number transition for financial values.
class AnimatedCurrencyText extends StatelessWidget {
  final double value;
  final TextStyle style;
  final Duration duration;
  final Curve curve;
  final String? prefix;

  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: duration,
      curve: curve,
      builder: (context, val, child) {
        final formatted = CurrencyFormatter.format(val);
        final displayText = prefix != null ? '$prefix$formatted' : formatted;
        return Text(
          displayText,
          style: style,
        );
      },
    );
  }
}

/// Custom Page Route Transitions
class MotionPageTransitions {
  MotionPageTransitions._();

  /// Smooth fade transition for tab switching in bottom navigation dock
  static Page<dynamic> fadeTransition({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 180),
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  /// Elegant slide-up + fade transition for modals and sub-screens
  static Page<dynamic> slideUpTransition({
    required Widget child,
    required LocalKey key,
    Duration duration = const Duration(milliseconds: 260),
  }) {
    return CustomTransitionPage<void>(
      key: key,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
