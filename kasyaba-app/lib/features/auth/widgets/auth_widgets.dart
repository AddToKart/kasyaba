import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app/theme/app_motion.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/kasyaba_tokens.dart';

/// ─────────────────────────────────────────────────────────────
///  Auth Design System — Figma Pixel-Perfect Tokens (Node 11:779)
/// ─────────────────────────────────────────────────────────────
class AuthFigmaTokens {
  AuthFigmaTokens._();

  // Color Fills & Strokes
  static const Color ebony = Color(0xFF0A1220); // Base canvas & button text
  static const Color ebony55 = Color(
    0x8C0A1220,
  ); // rgba(10, 18, 32, 0.55) - Input fields
  static const Color cello55 = Color(
    0x8C1E3A56,
  ); // rgba(30, 58, 86, 0.55) - Form card & Tooltip
  static const Color poloBlue28 = Color(
    0x478FB2CE,
  ); // rgba(143, 178, 206, 0.28) - Card / Tooltip border
  static const Color poloBlue35 = Color(
    0x598FB2CE,
  ); // rgba(143, 178, 206, 0.35) - Input border
  static const Color poloBlue = Color(
    0xFF8FB2CE,
  ); // Labels, subtitles, link text, logo bar 2
  static const Color periwinkleGray = Color(
    0xFFC9DCEA,
  ); // Primary button, headings, logo bar 1
  static const Color kashmirBlue = Color(
    0xFF4F7596,
  ); // Logo bar 3, Create account underline
  static const Color boulder = Color(0xFF757575); // Input placeholder
  static const Color white = Color(0xFFFFFFFF);

  // Radial Gradients
  static const Color radialGlow1 = Color(
    0xCC4F7596,
  ); // rgba(79, 117, 150, 0.8) at 85% 8%
  static const Color radialGlow2 = Color(
    0xFF1E3A56,
  ); // rgba(30, 58, 86, 1.0) at 0% 100%
  static const Color radialGlow3 = Color(
    0xAB1E3A56,
  ); // rgba(30, 58, 86, 0.67) at 100% 75%

  // Forgot Password (Node 11:3028) Tokens
  static const Color bigStone = Color(
    0xFF16293F,
  ); // Base input & back button fill on Forgot Pass
  static const Color poloBlue22 = Color(
    0x388FB2CE,
  ); // rgba(143, 178, 206, 0.22) - Border on Forgot Pass
  static const Color periwinkleGraySubtitle = Color(
    0xFFB4CDE0,
  ); // Subtitle and label on Forgot Pass
  static const Color radialForgotPass = Color(
    0xAB4F7596,
  ); // rgba(79, 117, 150, 0.67) at 90% 0%
}

// ── Squircle Back Button (Node 11:3033 & 11:743) ──
class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool hasBlur;

  const AuthBackButton({
    super.key,
    required this.onPressed,
    this.size = 50,
    this.radius = 24,
    this.backgroundColor,
    this.borderColor,
    this.hasBlur = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg =
        backgroundColor ??
        (isDark ? AuthFigmaTokens.bigStone : AppColors.lightCardSurface);
    final border =
        borderColor ??
        (isDark ? AuthFigmaTokens.poloBlue22 : AppColors.lightBorderHairline);

    Widget content = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border, width: 1.0),
      ),
      child: SvgPicture.asset(
        'assets/images/back_chevron.svg',
        width: 22,
        height: 22,
      ),
    );

    if (hasBlur) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

// ── Capsule Inline Field (Node 11:3041-3045, height: 56, r=28, fill: Big Stone #16293F) ──
class AuthCapsuleInlineField extends StatefulWidget {
  final String formControlName;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Map<String, ValidationMessageFunction>? validationMessages;
  final VoidCallback? onSubmitted;

  const AuthCapsuleInlineField({
    super.key,
    required this.formControlName,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.textInputAction,
    this.validationMessages,
    this.onSubmitted,
  });

  @override
  State<AuthCapsuleInlineField> createState() => _AuthCapsuleInlineFieldState();
}

class _AuthCapsuleInlineFieldState extends State<AuthCapsuleInlineField> {
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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 21),
      decoration: BoxDecoration(
        color: isDark ? AuthFigmaTokens.bigStone : AppColors.lightInputFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isFocused
              ? (isDark ? AuthFigmaTokens.poloBlue : KasyabaTokens.poloBlue)
              : (isDark
                    ? AuthFigmaTokens.poloBlue22
                    : AppColors.lightBorderHairline),
          width: _isFocused ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Fixed width prefix label (Node 11:3042, w: 72)
          SizedBox(
            width: 72,
            child: Text(
              widget.label,
              style: GoogleFonts.dmSans(
                color: isDark
                    ? AuthFigmaTokens.periwinkleGraySubtitle
                    : AppColors.lightTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          // Text Input Field without background discoloration (Node 11:3044-3045)
          Expanded(
            child: Theme(
              data: Theme.of(context).copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              child: ReactiveTextField<dynamic>(
                formControlName: widget.formControlName,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                onSubmitted: widget.onSubmitted != null
                    ? (_) => widget.onSubmitted!()
                    : null,
                style: GoogleFonts.dmSans(
                  color: isDark
                      ? AuthFigmaTokens.periwinkleGray
                      : AppColors.lightTextPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  filled: false,
                  fillColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  hintText: widget.hintText,
                  hintStyle: GoogleFonts.dmSans(
                    color: isDark
                        ? AuthFigmaTokens.periwinkleGray.withValues(alpha: 0.45)
                        : const Color(0xFF94A3B8),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                ),
                validationMessages: widget.validationMessages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Background with deep navy radial gradients and vector radar overlay ──
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

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base solid fill #0A1220
          Container(color: AuthFigmaTokens.ebony),
          // Radial Gradient 1: circle at 85% 8%, rgba(79, 117, 150, 0.8) 0% to rgba(79, 117, 150, 0) 70%
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.70, -0.84),
                radius: 0.70,
                colors: [AuthFigmaTokens.radialGlow1, Color(0x004F7596)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Radial Gradient 2: circle at 0% 100%, rgba(30, 58, 86, 1) 0% to rgba(30, 58, 86, 0) 70%
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1.0, 1.0),
                radius: 0.70,
                colors: [AuthFigmaTokens.radialGlow2, Color(0x001E3A56)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Radial Gradient 3: circle at 100% 75%, rgba(30, 58, 86, 0.67) 0% to rgba(30, 58, 86, 0) 70%
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1.0, 0.50),
                radius: 0.70,
                colors: [AuthFigmaTokens.radialGlow3, Color(0x001E3A56)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Vector radar background rings (Node 11:784)
          SvgPicture.asset(
            'assets/images/background_radar.svg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}

// ── Background for Forgot Password Screen (Node 11:3031) ──
class AuthForgotPassBackground extends StatelessWidget {
  final Size size;
  final bool isDark;

  const AuthForgotPassBackground({
    super.key,
    required this.size,
    required this.isDark,
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

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base solid fill #0A1220
          Container(color: AuthFigmaTokens.ebony),
          // Radial Gradient: circle at 90% 0%, rgba(79, 117, 150, 0.67) 0% to 0% at 70%
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.80, -1.0),
                radius: 0.70,
                colors: [AuthFigmaTokens.radialForgotPass, Color(0x004F7596)],
                stops: [0.0, 1.0],
              ),
            ),
          ),
          // Subtle radar background rings (Node 11:784)
          SvgPicture.asset(
            'assets/images/background_radar.svg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ],
      ),
    );
  }
}

// ── Kasyaba 3-Pill Logo Mark (Node 11:793-11:796) ──
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
          width: 34 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: AuthFigmaTokens.periwinkleGray,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
        ),
        SizedBox(height: 4 * scale),
        Container(
          width: 26 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: AuthFigmaTokens.poloBlue,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
        ),
        SizedBox(height: 4 * scale),
        Container(
          width: 18 * scale,
          height: 12 * scale,
          decoration: BoxDecoration(
            color: AuthFigmaTokens.kashmirBlue,
            borderRadius: BorderRadius.circular(6 * scale),
          ),
        ),
      ],
    );
  }
}

// ── Cohesive Brand Lockup Header (Node 11:791-11:798) ──
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
          style: GoogleFonts.bricolageGrotesque(
            color: isDark
                ? AuthFigmaTokens.periwinkleGray
                : AppColors.lightTextPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Runway Hero Spline (Node 11:785-11:790) ──
class RunwaySplineHero extends StatelessWidget {
  final String tooltipText;
  const RunwaySplineHero({super.key, this.tooltipText = 'Can I afford it?'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 342,
        height: 150,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Exact vector chart path + gradient + node + dashed drop line
            SvgPicture.asset(
              'assets/images/chart_vector.svg',
              width: 342,
              height: 150,
              fit: BoxFit.fill,
            ),
            // Floating "Can I afford it?" tooltip pill at exact Figma position (x: 112, y: 0)
            Positioned(
              left: 112,
              top: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AuthFigmaTokens.cello55,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AuthFigmaTokens.poloBlue28,
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      tooltipText,
                      style: GoogleFonts.dmSans(
                        color: AuthFigmaTokens.periwinkleGray,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Form Card (Node 11:807, 342px, r=32, p=23,19,21) ──
class AuthFormCard extends StatelessWidget {
  final Widget child;

  const AuthFormCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: Container(
          width: 342,
          padding: const EdgeInsets.only(
            top: 23,
            left: 19,
            right: 19,
            bottom: 21,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? AuthFigmaTokens.cello55
                : AppColors.lightCardSurface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark
                  ? AuthFigmaTokens.poloBlue28
                  : AppColors.lightBorderHairline,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── Explicit Label + Focus-Reactive Input Field (Node 11:808-813 & 11:814-819) ──
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
    final unfocusedIconColor = isDark
        ? AuthFigmaTokens.poloBlue
        : const Color(0xFF64748B);
    final focusedIconColor = isDark
        ? AuthFigmaTokens.periwinkleGray
        : KasyabaTokens.poloBlue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label in UPPERCASE (Node 11:810, 11:816)
        Text(
          widget.label.toUpperCase(),
          style: GoogleFonts.dmSans(
            color: isDark
                ? AuthFigmaTokens.poloBlue
                : AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 7),

        // Input container (height: 54, r: 27)
        SizedBox(
          height: 54,
          child: ReactiveTextField<dynamic>(
            formControlName: widget.formControlName,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: widget.onSubmitted != null
                ? (_) => widget.onSubmitted!()
                : null,
            style: GoogleFonts.dmSans(
              color: isDark
                  ? AuthFigmaTokens.periwinkleGray
                  : AppColors.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hintText,
              hintStyle: GoogleFonts.dmSans(
                color: isDark
                    ? AuthFigmaTokens.boulder
                    : const Color(0xFF94A3B8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              filled: true,
              fillColor: isDark
                  ? AuthFigmaTokens.ebony55
                  : AppColors.lightInputFill,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 15.5,
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
                borderRadius: BorderRadius.circular(27),
                borderSide: BorderSide(
                  color: isDark
                      ? AuthFigmaTokens.poloBlue35
                      : AppColors.lightBorderHairline,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(27),
                borderSide: BorderSide(
                  color: isDark ? AuthFigmaTokens.poloBlue : focusedIconColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(27),
                borderSide: const BorderSide(
                  color: KasyabaTokens.apricot,
                  width: 1.0,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(27),
                borderSide: const BorderSide(
                  color: KasyabaTokens.apricot,
                  width: 1.5,
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

// ── Primary Pill Button (Node 11:822-823, height: 60/56, r: 28, Periwinkle Gray) ──
class AuthPrimaryPillButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;
  final String label;
  final double height;

  const AuthPrimaryPillButton({
    super.key,
    required this.isLoading,
    required this.onPressed,
    required this.label,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AuthFigmaTokens.periwinkleGray,
          foregroundColor: AuthFigmaTokens.ebony,
          disabledBackgroundColor: AuthFigmaTokens.poloBlue.withValues(
            alpha: 0.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AuthFigmaTokens.ebony,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.dmSans(
                  color: AuthFigmaTokens.ebony,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ── Bottom Reassurance Footnote (Node 11:828-830) ──
class AuthTrustFooter extends StatelessWidget {
  const AuthTrustFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      'Calculated on your device. Your numbers stay yours.',
      textAlign: TextAlign.center,
      style: GoogleFonts.dmSans(
        color: isDark ? AuthFigmaTokens.poloBlue : AppColors.lightTextSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

// ── Live 4-Segment Password Strength Indicator ──
class PasswordStrengthBar extends StatelessWidget {
  final double strength; // 0 to 1

  const PasswordStrengthBar({super.key, required this.strength});

  @override
  Widget build(BuildContext context) {
    final normalized = strength.clamp(0.0, 1.0);
    if (normalized <= 0) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filled = (normalized * 4).ceil().clamp(1, 4).toInt();
    final (color, label) = switch (filled) {
      1 => (KasyabaTokens.apricot, 'Weak'),
      2 => (KasyabaTokens.casablanca, 'Fair'),
      3 => (KasyabaTokens.poloBlue, 'Good'),
      _ => (KasyabaTokens.bermuda, 'Strong'),
    };
    final trackColor = isDark
        ? KasyabaTokens.poloBlue22
        : AppColors.lightBorderHairline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: List.generate(4, (index) {
            final isFilled = index < filled;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: isFilled ? color : trackColor,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '$label password',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Min. 8 characters',
              maxLines: 1,
              style: TextStyle(
                color: isDark
                    ? KasyabaTokens.baliHai
                    : AppColors.lightTextSecondary,
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

    final color = isMatching ? KasyabaTokens.bermuda : KasyabaTokens.apricot;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            isMatching ? Icons.check_circle_rounded : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isMatching ? 'Passwords match' : 'Passwords do not match yet',
            style: TextStyle(
              color: color,
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

  const AuthErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: KasyabaTokens.apricot15,
        border: Border.all(
          color: KasyabaTokens.apricot.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: KasyabaTokens.apricot,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: KasyabaTokens.apricot,
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

// ── Terms of Service & Privacy Policy Checkbox (Figma Luxury Squircle) ──
class AuthTermsCheckbox extends StatelessWidget {
  final String formControlName;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  const AuthTermsCheckbox({
    super.key,
    required this.formControlName,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ReactiveFormField<bool, bool>(
      formControlName: formControlName,
      builder: (field) {
        final isChecked = field.value ?? false;
        final hasError = field.control.touched && field.control.hasErrors;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                field.control.value = !isChecked;
                field.control.markAsTouched();
              },
              borderRadius: BorderRadius.circular(8),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Squircle Checkbox
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1, right: 12),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? KasyabaTokens.bermuda
                            : (isDark
                                ? AuthFigmaTokens.bigStone
                                : AppColors.lightCardSurface),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: hasError
                              ? KasyabaTokens.apricot
                              : (isChecked
                                  ? KasyabaTokens.bermuda
                                  : (isDark
                                      ? AuthFigmaTokens.poloBlue28
                                      : AppColors.lightBorderHairline)),
                          width: 1.5,
                        ),
                        boxShadow: isChecked
                            ? [
                                BoxShadow(
                                  color: KasyabaTokens.bermuda.withValues(
                                    alpha: 0.35,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isChecked
                          ? const Center(
                              child: Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: KasyabaTokens.ebony,
                              ),
                            )
                          : null,
                    ),

                    // Label with interactive links
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: isDark
                                ? AuthFigmaTokens.poloBlue
                                : AppColors.lightTextSecondary,
                            height: 1.4,
                          ),
                          children: [
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: onTapTerms,
                                child: Text(
                                  'Terms & Conditions',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AuthFigmaTokens.periwinkleGray
                                        : AppColors.lightTextPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: isDark
                                        ? AuthFigmaTokens.poloBlue
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.baseline,
                              baseline: TextBaseline.alphabetic,
                              child: GestureDetector(
                                onTap: onTapPrivacy,
                                child: Text(
                                  'Privacy Policy',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AuthFigmaTokens.periwinkleGray
                                        : AppColors.lightTextPrimary,
                                    decoration: TextDecoration.underline,
                                    decorationColor: isDark
                                        ? AuthFigmaTokens.poloBlue
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Inline validation error matching user reference image
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: hasError
                  ? Padding(
                      padding: const EdgeInsets.only(left: 34, top: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              Icons.error_outline_rounded,
                              size: 13,
                              color: KasyabaTokens.apricot,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'You must accept the Terms & Conditions to proceed',
                              style: GoogleFonts.dmSans(
                                color: KasyabaTokens.apricot,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
