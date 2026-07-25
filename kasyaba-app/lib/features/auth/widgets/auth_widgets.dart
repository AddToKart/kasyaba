import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────
///  Shared auth screen widgets — used by Login & Register
/// ─────────────────────────────────────────────────────────────

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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      AppColors.obsidian,
                      AppColors.surface900,
                      AppColors.surface800,
                    ]
                  : [
                      const Color(0xFFF0FDF4),
                      const Color(0xFFF5F7FA),
                      const Color(0xFFECFDF5),
                    ],
            ),
          ),
          child: Stack(
            children: [
              // Orb 1 — top right emerald
              Positioned(
                top: -size.height * 0.15,
                right: -size.width * 0.25,
                child: Transform.rotate(
                  angle: rotateAnimation.value * 0.2,
                  child: Container(
                    width: size.width * 0.7,
                    height: size.width * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.emerald500.withValues(
                              alpha: isDark ? 0.18 : 0.10),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Orb 2 — bottom left gold
              Positioned(
                bottom: -size.height * 0.15,
                left: -size.width * 0.2,
                child: Transform.rotate(
                  angle: -rotateAnimation.value * 0.15,
                  child: Container(
                    width: size.width * 0.6,
                    height: size.width * 0.6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold400.withValues(
                              alpha: isDark ? 0.10 : 0.07),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (isDark) _GridOverlay(size: size),
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
      ..color = AppColors.surface700.withValues(alpha: 0.30)
      ..strokeWidth = 0.5;
    const step = 48.0;
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

class AuthLogoBadge extends StatelessWidget {
  final bool isDark;
  const AuthLogoBadge({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.emerald500.withValues(alpha: isDark ? 0.25 : 0.12),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald500.withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 38,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class AuthFormCard extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const AuthFormCard({super.key, required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: isDark
            ? AppColors.surface800.withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.92),
        border: Border.all(
          color: isDark
              ? AppColors.surface600.withValues(alpha: 0.7)
              : AppColors.lightBorder.withValues(alpha: 0.9),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.07),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          if (!isDark)
            BoxShadow(
              color: AppColors.emerald500.withValues(alpha: 0.04),
              blurRadius: 48,
              spreadRadius: 8,
            ),
        ],
      ),
      child: child,
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;
  const AuthErrorBanner(
      {super.key, required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.expense.withValues(alpha: isDark ? 0.12 : 0.08),
        border: Border.all(
          color: AppColors.expense.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.expense, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.expense,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool isDark;
  final bool autofocus;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.validator,
    this.suffixIcon,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      autofocus: autofocus,
      style: TextStyle(
        color: isDark ? AppColors.textDark : AppColors.textLight,
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Icon(icon, size: 20),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

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
        borderRadius: BorderRadius.circular(16),
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
                  color: AppColors.emerald500.withValues(alpha: 0.38),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isLoading ? AppColors.surface600 : Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
