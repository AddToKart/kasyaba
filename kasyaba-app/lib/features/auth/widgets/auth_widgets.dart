import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  Auth Design System — Luxury Dark Fintech Auth Widgets
/// ─────────────────────────────────────────────────────────────

// ── Background with soft radial emerald glow and subtle grid ──
class AuthBackground extends StatelessWidget {
  final Animation<double> rotateAnimation;
  final bool isDark;
  final Size size;

  const AuthBackground({
    super.key,
    required this.rotateAnimation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotateAnimation,
      builder: (_, _) {
        return Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            color: AppColors.obsidian,
          ),
          child: Stack(
            children: [
              // Subtle background grid
              _GridOverlay(size: size),

              // Soft radial emerald glow positioned behind header
              Positioned(
                top: -40,
                left: (size.width - 340) / 2,
                child: Container(
                  width: 340,
                  height: 300,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color.fromRGBO(16, 185, 129, 0.14),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              ),

              // Subtle champagne gold orb lower-left
              Positioned(
                bottom: -size.height * 0.1,
                left: -size.width * 0.2,
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.gold400.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GridOverlay extends StatelessWidget {
  final Size size;
  const _GridOverlay({required this.size});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: size, painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0FFFFFFF) // subtle grid line
      ..strokeWidth = 0.5;
    const step = 44.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}

// ── Cohesive Brand Lockup Header ──
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sleek differentiator pill badge above brand
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0x330F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.emerald500.withValues(alpha: 0.28),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald500.withValues(alpha: 0.08),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald400,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emerald400.withValues(alpha: 0.6),
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                '100% Deterministic • Zero AI • Private',
                style: TextStyle(
                  color: AppColors.emerald400,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Brand Lockup: Geometric Emblem + Bold Wordmark
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom Geometric Emblem
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.45),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald500.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.rotate(
                    angle: 0.785398, // 45 degrees diamond
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0x66D4AF37), // hairline gold
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.emerald400,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Bold KASYABA wordmark
            const Text(
              'KASYABA',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
                fontSize: 26,
                letterSpacing: 2.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Glassmorphic Form Card (rgba(15, 23, 42, 0.75) with blur: 12px) ──
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xBF0F172A), // rgba(15, 23, 42, 0.75)
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Explicit Label + Focus-Reactive Input Field ──
class AuthReactiveField extends StatefulWidget {
  final String formControlName;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Map<String, ValidationMessageFunction>? validationMessages;
  final VoidCallback? onSubmitted;

  const AuthReactiveField({
    super.key,
    required this.formControlName,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validationMessages,
    this.onSubmitted,
  });

  @override
  State<AuthReactiveField> createState() => _AuthReactiveFieldState();
}

class _AuthReactiveFieldState extends State<AuthReactiveField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const unfocusedIconColor = Color(0xFF64748B); // Muted slate
    const focusedIconColor = AppColors.emerald500; // #10B981

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicit, crisp typography label
        Text(
          widget.label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.emerald500.withValues(alpha: 0.16),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: ReactiveTextField<dynamic>(
            formControlName: widget.formControlName,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted != null
                ? (_) => widget.onSubmitted!()
                : null,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFF0B111D),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? focusedIconColor : unfocusedIconColor,
                size: 20,
              ),
              suffixIcon: widget.suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0x14FFFFFF), // 1px rgba(255,255,255,0.08)
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: focusedIconColor, // #10B981
                  width: 1.2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.expense,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.expense,
                  width: 1.2,
                ),
              ),
            ),
            validationMessages: widget.validationMessages,
          ),
        ),
      ],
    );
  }
}

// ── Primary Luxury Gradient Button (12px Radius) ──
class AuthGradientButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  const AuthGradientButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isLoading
            ? null
            : const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.emerald500.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading
              ? AppColors.surface600
              : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}

// ── Bottom Trust Footer ──
class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 13,
          color: Color(0xFF64748B), // Muted slate
        ),
        const SizedBox(width: 6),
        const Text(
          'End-to-end local & deterministic calculation',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Live 4-Segment Password Strength Indicator ──
class PasswordStrengthBar extends StatelessWidget {
  final int strength; // 0 to 4

  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    if (strength <= 0) return const SizedBox.shrink();

    final (color, label) = switch (strength) {
      1 => (AppColors.expense, 'Weak'),
      2 => (AppColors.warning, 'Fair'),
      3 => (AppColors.info, 'Good'),
      _ => (AppColors.emerald400, 'Strong'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < strength;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isFilled ? color : const Color(0x22FFFFFF),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$label password',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Text(
              'Min. 8 characters',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Live Password Match Indicator ──
class PasswordMatchIndicator extends StatelessWidget {
  final bool isMatching;
  final bool hasConfirmText;

  const PasswordMatchIndicator({
    super.key,
    required this.isMatching,
    required this.hasConfirmText,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasConfirmText) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isMatching
                ? Icons.check_circle_rounded
                : Icons.cancel_outlined,
            size: 14,
            color: isMatching ? AppColors.emerald400 : AppColors.expense,
          ),
          const SizedBox(width: 6),
          Text(
            isMatching ? 'Passwords match' : 'Passwords do not match yet',
            style: TextStyle(
              color: isMatching ? AppColors.emerald400 : AppColors.expense,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ──
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.expense.withValues(alpha: 0.12),
        border: Border.all(
          color: AppColors.expense.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.expense,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
