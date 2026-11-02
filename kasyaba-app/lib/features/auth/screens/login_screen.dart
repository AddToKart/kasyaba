import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final formGroup = FormGroup({
    'email': FormControl<String>(
      validators: [Validators.required, Validators.email],
    ),
    'password': FormControl<String>(validators: [Validators.required]),
  });

  late final AnimationController _bgController;
  late final AnimationController _entryController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _bgRotate;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
    _bgRotate = Tween<double>(begin: 0, end: 6.28).animate(_bgController);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );
    _entryController.forward();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _entryController.dispose();
    formGroup.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (ref.read(authProvider).isLoading) return;
    formGroup.markAllAsTouched();
    if (!formGroup.valid) return;
    try {
      await ref.read(authProvider.notifier).login(
            formGroup.control('email').value as String,
            formGroup.control('password').value as String,
          );
      if (mounted) context.go('/dashboard');
    } catch (_) {}
  }

  void _onForgotPasswordTapped(BuildContext context) {
    if (GoRouter.maybeOf(context) != null) {
      context.push('/forgot-password');
    } else {
      _showForgotPasswordHelp(context);
    }
  }

  void _showForgotPasswordHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? AuthFigmaTokens.cello55 : AppColors.lightCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark
                ? AuthFigmaTokens.poloBlue28
                : AppColors.lightBorderHairline,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.lock_reset_rounded,
              color: AuthFigmaTokens.poloBlue,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
              style: GoogleFonts.bricolageGrotesque(
                color: isDark
                    ? AuthFigmaTokens.periwinkleGray
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Enter the email you signed up with. We will send you a link to choose a new password.',
          style: GoogleFonts.dmSans(
            color:
                isDark ? AuthFigmaTokens.poloBlue : AppColors.lightTextSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Understood',
              style: GoogleFonts.dmSans(
                color: isDark
                    ? AuthFigmaTokens.periwinkleGray
                    : AppColors.emerald500,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
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
          // ── Background with exact Figma radial gradients & radar rings (Node 11:782-784) ──
          AuthBackground(
            rotateAnimation: _bgRotate,
            isDark: isDark,
            size: size,
          ),

          // ── Scrollable Content ────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 342),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: ReactiveForm(
                        formGroup: formGroup,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Top Brand Header Lockup (Node 11:791, 342x44) ──
                            const SizedBox(height: 12),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: AuthBrandHeader(),
                            ),
                            const SizedBox(height: 22),

                            // ── Runway Hero Spline + Tooltip (Node 11:785, 342x150) ──
                            const RunwaySplineHero(
                              tooltipText: 'Can I afford it?',
                            ),
                            const SizedBox(height: 18),

                            // ── Screen Title (Node 11:799) ──
                            Text(
                              'Welcome back.',
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

                            // ── Subtitle (Node 11:803) ──
                            Text(
                              'Pick up where your runway left off.',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                color: isDark
                                    ? AuthFigmaTokens.poloBlue
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // ── Form Card (Node 11:806, 342px, r=32) ──
                            AuthFormCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (authState.error != null) ...[
                                    AuthErrorBanner(
                                      message: authState.error!,
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // EMAIL Field
                                  AuthReactiveField(
                                    formControlName: 'email',
                                    label: 'Email',
                                    hintText: 'name@example.com',
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Email is required',
                                      ValidationMessage.email: (_) =>
                                          'Enter a valid email address',
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // PASSWORD Field
                                  AuthReactiveField(
                                    formControlName: 'password',
                                    label: 'Password',
                                    hintText: '••••••••',
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: _handleLogin,
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Password is required',
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Right-aligned "Forgot password?" link (Node 11:820)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: GestureDetector(
                                      onTap: () =>
                                          _onForgotPasswordTapped(context),
                                      behavior: HitTestBehavior.opaque,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Text(
                                          'Forgot password?',
                                          style: GoogleFonts.dmSans(
                                            color: isDark
                                                ? AuthFigmaTokens.poloBlue
                                                : AppColors.lightTextSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Primary Pill Button (Node 11:822, 60px high, r=28)
                                  AuthPrimaryPillButton(
                                    isLoading: authState.isLoading,
                                    onPressed: _handleLogin,
                                    label: 'Sign in',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Footer Navigation Link (Node 11:824-827) ──
                            Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'New to Kasyaba? ',
                                      style: GoogleFonts.dmSans(
                                        color: isDark
                                            ? AuthFigmaTokens.poloBlue
                                            : AppColors.lightTextSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.go('/register'),
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
                                          'Create account',
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
                              ),
                            ),
                            const SizedBox(height: 14),

                            // ── Bottom Reassurance Footnote (Node 11:828-830) ──
                            const AuthTrustFooter(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
