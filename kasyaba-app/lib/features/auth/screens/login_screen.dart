import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  void _showForgotPasswordHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F1E30) : AppColors.lightCardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0x3344688E) : AppColors.lightBorderHairline,
          ),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF90BDE8),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Reset Password',
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.lightTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: const Text(
          'Enter the email you signed up with. We will send you a link to choose a new password.',
          style: TextStyle(
            color: Color(0xFF8BA5C3),
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Understood',
              style: TextStyle(
                color: Color(0xFFD8E7F6),
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
      backgroundColor: isDark ? const Color(0xFF070F19) : AppColors.lightScaffold,
      body: Stack(
        children: [
          // ── Background with prominent deep navy glow & radar arcs ──
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
                  horizontal: 22,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: FadeTransition(
                    opacity: _fadeIn,
                    child: SlideTransition(
                      position: _slideUp,
                      child: ReactiveForm(
                        formGroup: formGroup,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Top Brand Header Lockup ────────
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: AuthBrandHeader(),
                            ),
                            const SizedBox(height: 14),

                            // ── Runway Spline Graphic & Tooltip ─
                            const RunwaySplineHero(
                              tooltipText: 'Can I afford it?',
                            ),
                            const SizedBox(height: 18),

                            // ── Screen Title & Subtitle ────────
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 34,
                                    letterSpacing: -0.7,
                                    color: isDark ? Colors.white : AppColors.lightTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pick up where your runway left off.',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    color: Color(0xFF86A0BD),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Glassmorphic Form Card (Very Round) ──
                            AuthFormCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (authState.error != null) ...[
                                    AuthErrorBanner(
                                      message: authState.error!,
                                    ),
                                    const SizedBox(height: 16),
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
                                  const SizedBox(height: 16),

                                  // PASSWORD Field (Clean, no eye icon as in Figma)
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
                                const SizedBox(height: 10),

                                // Right-aligned "Forgot password?" link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        _showForgotPasswordHelp(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        color: Color(0xFF85A5C7),
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // High-contrast soft ice-blue pill button
                                AuthPrimaryPillButton(
                                  isLoading: authState.isLoading,
                                  onPressed: _handleLogin,
                                  label: 'Sign in',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),

                          // ── Register Navigation Link ──────
                          Center(
                            child: GestureDetector(
                              onTap: () => context.go('/register'),
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'New to Kasyaba? ',
                                        style: TextStyle(
                                          color: Color(0xFF7E9EC2),
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'Create account',
                                        style: TextStyle(
                                          color: Color(0xFFE2EFF9),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                          decoration: TextDecoration.underline,
                                          decorationColor: Color(0xFFE2EFF9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ── Bottom Reassurance Footnote ───
                          const AuthTrustFooter(),
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
