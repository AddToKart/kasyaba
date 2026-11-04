import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/auth/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final formGroup = FormGroup({
    'email': FormControl<String>(
      validators: [Validators.required, Validators.email],
    ),
  });

  bool _isSubmitted = false;

  @override
  void dispose() {
    formGroup.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (ref.read(authProvider).isLoading) return;
    formGroup.markAllAsTouched();
    if (!formGroup.valid) return;

    final email = formGroup.control('email').value as String;
    try {
      await ref.read(authProvider.notifier).requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _isSubmitted = true;
        });
        context.push('/otp-verification', extra: {'email': email});
      }
    } catch (_) {
      // Error message is stored in authState.error
    }
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AuthFigmaTokens.ebony : AppColors.lightScaffold,
      body: Stack(
        children: [
          // ── Background with exact Figma radial gradient & radar arcs (Node 11:3031) ──
          AuthForgotPassBackground(
            size: size,
            isDark: isDark,
          ),

          // ── Main Layout: Top Form Content + Bottom Pinned Action Button ──
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
                              // ── Back Button (Node 11:3032-3034, 50x50, r=24) ──
                              Align(
                                alignment: Alignment.centerLeft,
                                child: AuthBackButton(
                                  onPressed: _handleBack,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Header Title (Node 11:3038) ──
                              Text(
                                'Reset your password',
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

                              // ── Subtitle (Node 11:3040) ──
                              Text(
                                'Enter the email you signed up with. We will send you a link to choose a new password.',
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

                              if (authState.error != null) ...[
                                AuthErrorBanner(message: authState.error!),
                                const SizedBox(height: 14),
                              ],

                              if (_isSubmitted) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KasyabaTokens.bermuda15,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: KasyabaTokens.bermuda.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: KasyabaTokens.bermuda,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Reset code sent! Please check your inbox.',
                                              style: GoogleFonts.dmSans(
                                                color: KasyabaTokens.bermuda,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      GestureDetector(
                                        onTap: () {
                                          final email = (formGroup
                                                  .control('email')
                                                  .value as String?) ??
                                              '';
                                          context.push(
                                            '/otp-verification',
                                            extra: {'email': email},
                                          );
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Text(
                                          'Enter verification code →',
                                          style: GoogleFonts.dmSans(
                                            color: KasyabaTokens.bermuda,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],

                              // ── Email Input Capsule Card (Node 11:3041-3045, height: 56, r=28) ──
                              AuthCapsuleInlineField(
                                formControlName: 'email',
                                label: 'Email',
                                hintText: 'name@example.com',
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                onSubmitted: _handleSendResetLink,
                                validationMessages: {
                                  ValidationMessage.required: (_) =>
                                      'Email is required',
                                  ValidationMessage.email: (_) =>
                                      'Enter a valid email address',
                                },
                              ),
                              const SizedBox(height: 16),

                              // ── Remembered it? Sign in (Node 11:3046-3049) ──
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Remembered it? ',
                                    style: GoogleFonts.dmSans(
                                      color: isDark
                                          ? AuthFigmaTokens
                                              .periwinkleGraySubtitle
                                          : AppColors.lightTextSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      decoration: const BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: AuthFigmaTokens.kashmirBlue,
                                            width: 2.0,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'Sign in',
                                        style: GoogleFonts.dmSans(
                                          color: isDark
                                              ? AuthFigmaTokens.periwinkleGray
                                              : AppColors.lightTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Send reset link Button Pinned to Bottom (Node 11:3050-3052, height: 56, r=28) ──
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
                              : _handleSendResetLink,
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
                                  'Send reset link',
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
