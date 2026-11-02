import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  Auth Design System — Luxury Dark Fintech Auth Widgets
/// ─────────────────────────────────────────────────────────────

// ── Background with deep navy night gradient (Radar rings removed per request) ──
class AuthBackground extends StatelessWidget {
  final Animation<double>? rotateAnimation;
  final bool isDark;
  final Size size;

  const AuthBackground({
    super.key,
    this.rotateAnimation,
    required this.isDark,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      return Container(
        width: size.width,
        height: size.height,
        color: AppColors.lightScaffold,
      );
    }

    return Container(
      width: size.width,
      height: size.height,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF162F4B), // Celestial steel blue top right
            Color(0xFF0C1929), // Rich navy center
            Color(0xFF060E18), // Deep bottom base
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Soft ambient celestial glow at top-right corner
          Positioned(
            right: -size.width * 0.2,
            top: -size.width * 0.2,
            child: Container(
              width: size.width * 1.1,
              height: size.width * 1.1,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0x40255585),
                    Colors.transparent,
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kasyaba 3-Pill Logo Mark (Full Capsule Radius) ──
class KasyabaLogoMark extends StatelessWidget {
  final double scale;
  const KasyabaLogoMark({super.key, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28 * scale,
          height: 5.5 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF99C5F0),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        SizedBox(height: 4 * scale),
        Container(
          width: 20 * scale,
          height: 5.5 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF6098CF),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        SizedBox(height: 4 * scale),
        Container(
          width: 13 * scale,
          height: 5.5 * scale,
          decoration: BoxDecoration(
            color: const Color(0xFF3D6E9E),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

// ── Cohesive Brand Lockup Header ──
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const KasyabaLogoMark(),
        const SizedBox(width: 12),
        Text(
          'Kasyaba',
          style: TextStyle(
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

// ── Runway Hero Spline with Prominent White Curve, Glowing Gradient Fill, and Inflection Node ──
class RunwaySplineHero extends StatelessWidget {
  final String tooltipText;
  const RunwaySplineHero({
    super.key,
    this.tooltipText = 'Can I afford it?',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 125.0;
        final crestX = width * 0.69;
        const crestY = 50.0;

        return SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Curve, Prominent Gradient Fill under curve, dashed drop line, and glowing inflection node
              CustomPaint(
                size: Size(width, height),
                painter: _RunwaySplinePainter(
                  crestX: crestX,
                  crestY: crestY,
                ),
              ),

              // Floating "Can I afford it?" capsule tooltip
              // Positioned above the valley to the left of the peak node with zero overlap
              Positioned(
                top: 6.0,
                left: (width * 0.36).clamp(0.0, width - 135),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB80E1C2E),
                    borderRadius: BorderRadius.circular(999), // Full capsule
                    border: Border.all(
                      color: const Color(0x668EBCDE), // Crisp light blue border
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    tooltipText,
                    style: const TextStyle(
                      color: Color(0xFFE2EEF8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
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

class _RunwaySplinePainter extends CustomPainter {
  final double crestX;
  final double crestY;

  _RunwaySplinePainter({
    required this.crestX,
    required this.crestY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // ── 1. The Bold Spline Path ──────────────────────
    final path = Path();
    path.moveTo(0, height * 0.68);

    // Climb smoothly to first crest
    path.cubicTo(
      width * 0.10,
      height * 0.62,
      width * 0.16,
      height * 0.50,
      width * 0.24,
      height * 0.50,
    );
    // Dip down into valley
    path.cubicTo(
      width * 0.32,
      height * 0.50,
      width * 0.38,
      height * 0.66,
      width * 0.46,
      height * 0.66,
    );
    // Steep sharp rise to the peak node
    path.cubicTo(
      width * 0.54,
      height * 0.66,
      crestX - 22,
      crestY,
      crestX,
      crestY,
    );
    // Arch over the peak like a hill towards the right edge
    path.cubicTo(
      crestX + 22,
      crestY,
      width * 0.85,
      crestY - 14,
      width,
      crestY - 8,
    );

    // ── 2. Prominent Fading White Gradient Under Curve ──
    final fillPath = Path.from(path);
    fillPath.lineTo(width, height);
    fillPath.lineTo(0, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x55FFFFFF), // Very prominent milky white at curve
          Color(0x2280B5E8), // Soft blue luminous mid
          Color(0x060D1E30), // Fades down smoothly
          Color(0x00000000),
        ],
        stops: [0.0, 0.35, 0.78, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // ── 3. Solid Sharp White Stroke ──────────────────
    final strokePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.drawPath(path, strokePaint);

    // ── 4. Vertical Dashed Drop Line from Peak ───────
    final dashPaint = Paint()
      ..color = const Color(0x80FFFFFF)
      ..strokeWidth = 1.5;

    const dashLength = 4.0;
    const dashSpace = 4.0;
    double currentY = crestY + 11;
    final bottomY = height;

    while (currentY < bottomY) {
      canvas.drawLine(
        Offset(crestX, currentY),
        Offset(crestX, (currentY + dashLength).clamp(crestY, bottomY)),
        dashPaint,
      );
      currentY += dashLength + dashSpace;
    }

    // ── 5. Prominent Inflection Peak Node ────────────
    final peak = Offset(crestX, crestY);
    final haloPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..isAntiAlias = true;
    final haloFillPaint = Paint()
      ..color = const Color(0xFF13283E)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(peak, 8.5, haloFillPaint);
    canvas.drawCircle(peak, 8.5, haloPaint);

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawCircle(peak, 3.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _RunwaySplinePainter oldDelegate) =>
      oldDelegate.crestX != crestX || oldDelegate.crestY != crestY;
}

// ── Super-Rounded Glassmorphic Form Card (28px Radius) ──
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xCC0E1A29) // Translucent deep navy
              : AppColors.lightCardSurface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark
                ? const Color(0x3344688E) // Crisp soft blue border
                : AppColors.lightBorderHairline,
            width: 1.0,
          ),
          boxShadow: [
            if (isDark)
              const BoxShadow(
                color: Color(0x40000000),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
          ],
        ),
        child: child,
      ),
    );
  }
}

// ── Explicit Label + Focus-Reactive Input Field ──
class AuthReactiveField extends StatefulWidget {
  final String formControlName;
  final String label;
  final String hintText;
  final IconData? prefixIcon;
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
    this.prefixIcon,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unfocusedIconColor = isDark ? const Color(0xFF5B7591) : const Color(0xFF64748B);
    final focusedIconColor = isDark ? const Color(0xFF90BDE8) : AppColors.emerald500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Explicit, crisp typography label
        Text(
          widget.label.toUpperCase(),
          style: TextStyle(
            color: isDark ? const Color(0xFF7E9EC2) : AppColors.lightTextSecondary,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [],
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
            style: TextStyle(
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: isDark ? const Color(0xFF4C6A8A) : const Color(0xFF94A3B8),
                fontSize: 14.5,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF07111D) : AppColors.lightInputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 17,
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      color: _isFocused ? focusedIconColor : unfocusedIconColor,
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isDark ? const Color(0x383F6288) : AppColors.lightBorderHairline,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(
                  color: isDark ? const Color(0xFF7CB2E8) : focusedIconColor,
                  width: 1.4,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(
                  color: AppColors.expense,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
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

// ── Primary High-Contrast Pill Button (Carbon copy of Figma) ──
class AuthPrimaryPillButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  const AuthPrimaryPillButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD3E4F4),
        foregroundColor: const Color(0xFF091422),
        disabledBackgroundColor: const Color(0xFF8BA5C3),
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999), // Full capsule pill
        ),
        elevation: 0,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Color(0xFF091422),
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                color: Color(0xFF091422),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
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
        borderRadius: BorderRadius.circular(10),
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
            borderRadius: BorderRadius.circular(10),
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

// ── Bottom Reassurance Footnote (Carbon copy of Figma) ──
class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Calculated on your device. Your numbers stay yours.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDark ? const Color(0xFF5B7591) : AppColors.lightTextSecondary,
        fontSize: 11.5,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
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
        borderRadius: BorderRadius.circular(10),
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
