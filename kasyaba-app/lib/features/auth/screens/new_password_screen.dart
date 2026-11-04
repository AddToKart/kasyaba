import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../widgets/auth_widgets.dart';

class NewPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String resetToken;

  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final formGroup = FormGroup(
    {
      'newPassword': FormControl<String>(
        validators: [
          Validators.required,
          Validators.minLength(8),
        ],
      ),
      'confirmPassword': FormControl<String>(
        validators: [Validators.required],
      ),
    },
    validators: [
      Validators.mustMatch('newPassword', 'confirmPassword'),
    ],
  );

  String? _localError;

  @override
  void dispose() {
    formGroup.dispose();
    super.dispose();
  }

  double _passwordStrength(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      score++;
    }
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return (score / 5).clamp(0.0, 1.0).toDouble();
  }

  Future<void> _handleResetPassword() async {
    if (ref.read(authProvider).isLoading) return;
    formGroup.markAllAsTouched();
    if (!formGroup.valid) return;

    final newPassword = formGroup.control('newPassword').value as String;

    setState(() {
      _localError = null;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(
            resetToken: widget.resetToken,
            newPassword: newPassword,
          );

      if (!mounted) return;

      KasyabaToast.showSuccess(
        context,
        'Password updated! Please sign in with your new password.',
      );
      context.go('/login');
    } catch (_) {
      if (mounted) {
        final authError = ref.read(authProvider).error;
        if (authError != null && authError.toLowerCase().contains('expired')) {
          KasyabaToast.showError(
            context,
            'Reset session expired. Please request a new verification code.',
          );
          context.go('/forgot-password');
        } else {
          setState(() {
            _localError = authError ?? 'Failed to update password. Try again.';
          });
        }
      }
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/forgot-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final errorMessage = _localError ?? authState.error;

    return Scaffold(
      backgroundColor: isDark ? AuthFigmaTokens.ebony : AppColors.lightScaffold,
      body: Stack(
        children: [
          AuthForgotPassBackground(size: size, isDark: isDark),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 350),
                        child: ReactiveForm(
                          formGroup: formGroup,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AuthBackButton(onPressed: _handleBack),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'New password',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 32,
                                  height: 1.1,
                                  color: isDark
                                      ? AuthFigmaTokens.periwinkleGray
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Set a strong password to secure your Kasyaba account.',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 1.45,
                                  color: isDark
                                      ? AuthFigmaTokens.periwinkleGraySubtitle
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (errorMessage != null) ...[
                                AuthErrorBanner(message: errorMessage),
                                const SizedBox(height: 14),
                              ],

                              // ── New Password Field ──
                              AuthReactiveField(
                                formControlName: 'newPassword',
                                label: 'New password',
                                hintText: 'At least 8 characters',
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                validationMessages: {
                                  ValidationMessage.required: (_) =>
                                      'Password is required',
                                  ValidationMessage.minLength: (_) =>
                                      'At least 8 characters required',
                                },
                              ),
                              ReactiveFormConsumer(
                                builder: (context, form, child) {
                                  final password =
                                      (form.control('newPassword').value
                                              as String?) ??
                                          '';
                                  return PasswordStrengthBar(
                                    strength: _passwordStrength(password),
                                  );
                                },
                              ),
                              const SizedBox(height: 14),

                              // ── Confirm Password Field ──
                              AuthReactiveField(
                                formControlName: 'confirmPassword',
                                label: 'Confirm password',
                                hintText: 'Re-enter your password',
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _handleResetPassword,
                                validationMessages: {
                                  ValidationMessage.required: (_) =>
                                      'Please confirm your password',
                                  ValidationMessage.mustMatch: (_) =>
                                      'Passwords do not match',
                                },
                              ),
                              ReactiveFormConsumer(
                                builder: (context, form, child) {
                                  final password =
                                      (form.control('newPassword').value
                                              as String?) ??
                                          '';
                                  final confirm =
                                      (form.control('confirmPassword').value
                                              as String?) ??
                                          '';
                                  return PasswordMatchIndicator(
                                    isMatching: password.isNotEmpty &&
                                        confirm.isNotEmpty &&
                                        password == confirm,
                                    hasConfirmText: confirm.isNotEmpty,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Reset Password Action Button Pinned to Bottom ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 350),
                      child: SizedBox(
                        height: 56,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: authState.isLoading
                              ? null
                              : _handleResetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AuthFigmaTokens.periwinkleGray,
                            foregroundColor: AuthFigmaTokens.ebony,
                            disabledBackgroundColor: AuthFigmaTokens.poloBlue
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: AuthFigmaTokens.ebony,
                                  ),
                                )
                              : Text(
                                  'Reset password',
                                  style: GoogleFonts.dmSans(
                                    color: AuthFigmaTokens.ebony,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
