import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).register(
            _emailController.text.trim(),
            _passwordController.text,
            displayName: _nameController.text.trim(),
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
                        horizontal: 28, vertical: 24),
                    child: FadeTransition(
                      opacity: _fadeIn,
                      child: SlideTransition(
                        position: _slideUp,
                        child: Form(
                          key: _formKey,
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

                                    AuthTextField(
                                      controller: _nameController,
                                      label: 'Full Name',
                                      hint: 'John Doe',
                                      icon: Icons.person_outline_rounded,
                                      isDark: isDark,
                                      validator: (v) =>
                                          (v?.trim().length ?? 0) >= 1
                                              ? null
                                              : 'Please enter your name',
                                    ),
                                    const SizedBox(height: 16),

                                    AuthTextField(
                                      controller: _emailController,
                                      label: 'Email Address',
                                      hint: 'name@example.com',
                                      icon: Icons.alternate_email_rounded,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      isDark: isDark,
                                      validator: (v) =>
                                          v?.contains('@') == true
                                              ? null
                                              : 'Enter a valid email',
                                    ),
                                    const SizedBox(height: 16),

                                    AuthTextField(
                                      controller: _passwordController,
                                      label: 'Password',
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      isDark: isDark,
                                      validator: (v) =>
                                          (v?.length ?? 0) >= 8
                                              ? null
                                              : 'At least 8 characters',
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
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ),
                                    const SizedBox(height: 16),

                                    AuthTextField(
                                      controller: _confirmPasswordController,
                                      label: 'Confirm Password',
                                      hint: '••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _handleRegister(),
                                      isDark: isDark,
                                      validator: (v) =>
                                          v == _passwordController.text
                                              ? null
                                              : 'Passwords do not match',
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 20,
                                        ),
                                        color: isDark
                                            ? AppColors.textMuted
                                            : AppColors.textMutedL,
                                        onPressed: () => setState(() =>
                                            _obscureConfirm = !_obscureConfirm),
                                      ),
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
                                        horizontal: 16, vertical: 10),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/login'),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isDark
                ? AppColors.surface700.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85),
            border: Border.all(
              color:
                  isDark ? AppColors.surface600 : AppColors.lightBorder,
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
    );
  }
}
