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
  bool _obscurePassword = true;

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
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface800,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0x14FFFFFF)),
        ),
        title: const Row(
          children: [
            Icon(
              Icons.lock_reset_rounded,
              color: AppColors.gold400,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Reset Password',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: const Text(
          'For your privacy and security, password resets are processed via your verified email address or master recovery key. Contact support or your administrator to request a reset token.',
          style: TextStyle(
            color: AppColors.textMuted,
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
                color: AppColors.emerald400,
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

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      body: Stack(
        children: [
          // ── Background with grid & emerald aura ───────────
          AuthBackground(
            rotateAnimation: _bgRotate,
            isDark: true,
            size: size,
          ),

          // ── Scrollable Content ────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: ReactiveForm(
                      formGroup: formGroup,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Upgraded Brand Header Lockup ──
                          const AuthBrandHeader(),
                          const SizedBox(height: 24),

                          // ── Screen Title ──────────────────
                          const Center(
                            child: Column(
                              children: [
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                    letterSpacing: -0.6,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Sign in to access your financial runway',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Glassmorphic Form Card ────────
                          AuthFormCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (authState.error != null) ...[
                                  AuthErrorBanner(
                                    message: authState.error!,
                                  ),
                                  const SizedBox(height: 18),
                                ],

                                // Explicit label + envelope icon
                                AuthReactiveField(
                                  formControlName: 'email',
                                  label: 'Email Address',
                                  hintText: 'name@example.com',
                                  prefixIcon: Icons.mail_outline_rounded,
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

                                // Explicit label + lock icon
                                AuthReactiveField(
                                  formControlName: 'password',
                                  label: 'Password',
                                  hintText: '••••••••',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: _handleLogin,
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 19,
                                    ),
                                    color: const Color(0xFF64748B),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validationMessages: {
                                    ValidationMessage.required: (_) =>
                                        'Password is required',
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Right-aligned "Forgot Password?" link
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        _showForgotPasswordHelp(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Primary Sign In button (12px radius)
                                AuthGradientButton(
                                  isLoading: authState.isLoading,
                                  onPressed: _handleLogin,
                                  label: 'Sign In',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Register Navigation Link ──────
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Don't have an account?  ",
                                      style: TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 13.5,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Create one',
                                      style: TextStyle(
                                        color: AppColors.emerald400,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── Bottom Trust Footer ───────────
                          const AuthTrustFooter(),
                        ],
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
