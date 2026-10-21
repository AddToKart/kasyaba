import 'package:flutter/material.dart';
import '../../app/theme/app_motion.dart';

/// ─────────────────────────────────────────────────────────────
///  PressableScale — Spring Physics Touch Wrapper
///  Compreses the wrapped widget to [scaleDown] (default 0.96) on touch-down
///  and bounces back on release with a satisfying tactile haptic click.
/// ─────────────────────────────────────────────────────────────

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final bool enabled;
  final bool enableHaptics;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
    this.enabled = true,
    this.enableHaptics = true,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  bool _isPressed = false;

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
  void didUpdateWidget(PressableScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scaleDown != widget.scaleDown) {
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled || (widget.onTap == null && widget.onLongPress == null)) {
      return;
    }
    _isPressed = true;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
    if (widget.enableHaptics) {
      AppHaptics.lightImpact();
    }
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!_isPressed) return;
    _isPressed = false;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = widget.enabled &&
        (widget.onTap != null || widget.onLongPress != null);

    if (!isInteractive) {
      return widget.child;
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
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

