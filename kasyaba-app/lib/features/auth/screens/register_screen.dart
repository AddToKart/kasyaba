import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../app/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  final formGroup = FormGroup(
    {
      'name': FormControl<String>(validators: [Validators.required]),
      'email': FormControl<String>(
        validators: [Validators.required, Validators.email],
      ),
      'password': FormControl<String>(
        validators: [Validators.required, Validators.minLength(8)],
      ),
      'confirmPassword': FormControl<String>(validators: [Validators.required]),
    },
    validators: [Validators.mustMatch('password', 'confirmPassword')],
  );
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

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
    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
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

  Future<void> _handleRegister() async {
    if (ref.read(authProvider).isLoading) return;
    formGroup.markAllAsTouched();
    if (!formGroup.valid) return;
    try {
      await ref
          .read(authProvider.notifier)
          .register(
            formGroup.control('email').value as String,
            formGroup.control('password').value as String,
            displayName: formGroup.control('name').value as String,
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
            child: Stack(
              children: [
                // Back button
                Positioned(
                  top: 8,
                  left: 12,
                  child: _AuthBackButton(isDark: isDark),
                ),

                Center(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
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
                              const SizedBox(height: 44),

                              // ── Branding ─────────────────
                              Center(
                                child: Column(
                                  children: [
                                    AuthLogoBadge(isDark: isDark),
                                    const SizedBox(height: 28),
                                    Text(
                                      'Create Account',
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
                                      'Join Kasyaba and master your finances',
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
                              const SizedBox(height: 36),

                              // ── Form Card ────────────────
                              AuthFormCard(
                                isDark: isDark,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (authState.error != null) ...[
                                      AuthErrorBanner(
                                        message: authState.error!,
                                        isDark: isDark,
                                      ),
                                      const SizedBox(height: 20),
                                    ],

                                    ReactiveTextField(
                                      formControlName: 'name',
                                      textInputAction: TextInputAction.next,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textDark
                                            : AppColors.textLight,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        hintText: 'John Doe',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Icon(
                                            Icons.person_outline_rounded,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'Please enter your name',
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    ReactiveTextField(
                                      formControlName: 'email',
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textDark
                                            : AppColors.textLight,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        hintText: 'name@example.com',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Icon(
                                            Icons.alternate_email_rounded,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'Email is required',
                                        ValidationMessage.email: (_) =>
                                            'Enter a valid email',
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    ReactiveTextField(
                                      formControlName: 'password',
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textDark
                                            : AppColors.textLight,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Password',
                                        hintText: '••••••••',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            size: 20,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscurePassword
                                              ? 'Show password'
                                              : 'Hide password',
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                          color: isDark
                                              ? AppColors.textMuted
                                              : AppColors.textMutedL,
                                          onPressed: () => setState(
                                            () => _obscurePassword =
                                                !_obscurePassword,
                                          ),
                                        ),
                                      ),
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'At least 8 characters',
                                        ValidationMessage.minLength: (_) =>
                                            'At least 8 characters',
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    ReactiveTextField(
                                      formControlName: 'confirmPassword',
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _handleRegister(),
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.textDark
                                            : AppColors.textLight,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Confirm Password',
                                        hintText: '••••••••',
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 4,
                                          ),
                                          child: Icon(
                                            Icons.lock_outline_rounded,
                                            size: 20,
                                          ),
                                        ),
                                        suffixIcon: IconButton(
                                          tooltip: _obscureConfirm
                                              ? 'Show password'
                                              : 'Hide password',
                                          constraints: const BoxConstraints(
                                            minWidth: 48,
                                            minHeight: 48,
                                          ),
                                          icon: Icon(
                                            _obscureConfirm
                                                ? Icons.visibility_off_outlined
                                                : Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                          color: isDark
                                              ? AppColors.textMuted
                                              : AppColors.textMutedL,
                                          onPressed: () => setState(
                                            () => _obscureConfirm =
                                                !_obscureConfirm,
                                          ),
                                        ),
                                      ),
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'Please confirm your password',
                                        ValidationMessage.mustMatch: (_) =>
                                            'Passwords do not match',
                                      },
                                    ),
                                    const SizedBox(height: 28),

                                    AuthGradientButton(
                                      isLoading: authState.isLoading,
                                      onPressed: _handleRegister,
                                      label: 'Create Account',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              // ── Sign In Link ─────────────
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                  ),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Already have an account?  ',
                                          style: TextStyle(
                                            color: isDark
                                                ? AppColors.textMuted
                                                : AppColors.textMutedL,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const TextSpan(
                                          text: 'Sign In',
                                          style: TextStyle(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
  final bool isDark;
  const _AuthBackButton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back to sign in',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/login'),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark
                  ? AppColors.surface700.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border.all(
                color: isDark ? AppColors.surface600 : AppColors.lightBorder,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }
}
