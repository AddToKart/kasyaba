import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final formGroup = FormGroup({
    'email': FormControl<String>(validators: [
      Validators.required,
      Validators.email,
    ]),
    'password': FormControl<String>(validators: [
      Validators.required,
    ]),
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
    _bgRotate =
        Tween<double>(begin: 0, end: 6.28).animate(_bgController);
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn =
        CurvedAnimation(parent: _entryController, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── Background ───────────────────────────────────
          AuthBackground(
            rotateAnimation: _bgRotate,
            isDark: isDark,
            size: size,
          ),

          // ── Content ──────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: SlideTransition(
                    position: _slideUp,
                    child: ReactiveForm(
                      formGroup: formGroup,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Branding ─────────────────────
                          Center(
                            child: Column(
                              children: [
                                AuthLogoBadge(isDark: isDark),
                                const SizedBox(height: 28),
                                Text(
                                  'Welcome Back',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.8,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textLight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sign in to your Kasyaba account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textMuted
                                        : AppColors.textMutedL,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),

                          // ── Form Card ────────────────────
                          AuthFormCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (authState.error != null) ...[
                                  AuthErrorBanner(
                                    message: authState.error!,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 20),
                                ],

                                ReactiveTextField(
                                  formControlName: 'email',
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                    color: isDark ? AppColors.textDark : AppColors.textLight,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    hintText: 'name@example.com',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(Icons.alternate_email_rounded, size: 20),
                                    ),
                                  ),
                                  validationMessages: {
                                    ValidationMessage.required: (_) => 'Email is required',
                                    ValidationMessage.email: (_) => 'Enter a valid email',
                                  },
                                ),
                                const SizedBox(height: 16),

                                ReactiveTextField(
                                  formControlName: 'password',
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _handleLogin(),
                                  style: TextStyle(
                                    color: isDark ? AppColors.textDark : AppColors.textLight,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    hintText: '••••••••',
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(Icons.lock_outline_rounded, size: 20),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 20,
                                      ),
                                      color: isDark
                                          ? AppColors.textMuted
                                          : AppColors.textMutedL,
                                      onPressed: () => setState(() =>
                                          _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  validationMessages: {
                                    ValidationMessage.required: (_) => 'Password is required',
                                  },
                                ),
                                const SizedBox(height: 28),

                                AuthGradientButton(
                                  isLoading: authState.isLoading,
                                  onPressed: _handleLogin,
                                  label: 'Sign In',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Register Link ─────────────────
                          Center(
                            child: TextButton(
                              onPressed: () => context.go('/register'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "Don't have an account?  ",
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textMuted
                                            : AppColors.textMutedL,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Create one',
                                      style: const TextStyle(
                                        color: AppColors.emerald500,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
