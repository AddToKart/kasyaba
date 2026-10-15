import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_provider.dart';
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
  int _passwordStrength = 0;
  bool _isPasswordMatching = false;
  bool _hasConfirmText = false;

  StreamSubscription<dynamic>? _passwordSub;
  StreamSubscription<dynamic>? _confirmSub;

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

    // Listen to password strength & matching
    _passwordSub = formGroup.control('password').valueChanges.listen((val) {
      final pwd = val?.toString() ?? '';
      final confirm = formGroup.control('confirmPassword').value?.toString() ?? '';
      if (mounted) {
        setState(() {
          _passwordStrength = _computeStrength(pwd);
          _hasConfirmText = confirm.isNotEmpty;
          _isPasswordMatching = pwd.isNotEmpty && pwd == confirm;
        });
      }
    });

    _confirmSub = formGroup.control('confirmPassword').valueChanges.listen((val) {
      final confirm = val?.toString() ?? '';
      final pwd = formGroup.control('password').value?.toString() ?? '';
      if (mounted) {
        setState(() {
          _hasConfirmText = confirm.isNotEmpty;
          _isPasswordMatching = pwd.isNotEmpty && pwd == confirm;
        });
      }
    });
  }

  int _computeStrength(String pwd) {
    if (pwd.isEmpty) return 0;
    int score = 0;
    if (pwd.length >= 8) score++;
    if (pwd.length >= 12) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd) && RegExp(r'[a-zA-Z]').hasMatch(pwd)) {
      score++;
    }
    if (RegExp(r'[^a-zA-Z0-9]').hasMatch(pwd) ||
        (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd))) {
      score++;
    }
    return score.clamp(1, 4);
  }

  @override
  void dispose() {
    _passwordSub?.cancel();
    _confirmSub?.cancel();
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
      await ref.read(authProvider.notifier).register(
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
            child: Stack(
              children: [
                // Top-left back button
                Positioned(
                  top: 8,
                  left: 12,
                  child: _AuthBackButton(),
                ),

                Center(
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
                              const SizedBox(height: 38),

                              // ── Upgraded Brand Header Lockup ──
                              const AuthBrandHeader(),
                              const SizedBox(height: 24),

                              // ── Screen Title ──────────────────
                              const Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'Create Account',
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
                                      'Start tracking your deterministic runway today',
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (authState.error != null) ...[
                                      AuthErrorBanner(
                                        message: authState.error!,
                                      ),
                                      const SizedBox(height: 18),
                                    ],

                                    // Full Name Field
                                    AuthReactiveField(
                                      formControlName: 'name',
                                      label: 'Full Name',
                                      hintText: 'John Doe',
                                      prefixIcon: Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'Please enter your name',
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Email Address Field with Envelope Icon
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

                                    // Password Field
                                    AuthReactiveField(
                                      formControlName: 'password',
                                      label: 'Password',
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscurePassword,
                                      textInputAction: TextInputAction.next,
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
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                      ),
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'At least 8 characters required',
                                        ValidationMessage.minLength: (_) =>
                                            'At least 8 characters required',
                                      },
                                    ),

                                    // Live 4-segment Password Strength Indicator
                                    PasswordStrengthBar(
                                      strength: _passwordStrength,
                                    ),
                                    const SizedBox(height: 16),

                                    // Confirm Password Field
                                    AuthReactiveField(
                                      formControlName: 'confirmPassword',
                                      label: 'Confirm Password',
                                      hintText: '••••••••',
                                      prefixIcon: Icons.lock_outline_rounded,
                                      obscureText: _obscureConfirm,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: _handleRegister,
                                      suffixIcon: IconButton(
                                        tooltip: _obscureConfirm
                                            ? 'Show password'
                                            : 'Hide password',
                                        icon: Icon(
                                          _obscureConfirm
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 19,
                                        ),
                                        color: const Color(0xFF64748B),
                                        onPressed: () => setState(
                                          () => _obscureConfirm =
                                              !_obscureConfirm,
                                        ),
                                      ),
                                      validationMessages: {
                                        ValidationMessage.required: (_) =>
                                            'Please confirm your password',
                                        ValidationMessage.mustMatch: (_) =>
                                            'Passwords do not match',
                                      },
                                    ),

                                    // Live Match Indicator
                                    PasswordMatchIndicator(
                                      isMatching: _isPasswordMatching,
                                      hasConfirmText: _hasConfirmText,
                                    ),
                                    const SizedBox(height: 24),

                                    // Primary Create Account Button (12px radius)
                                    AuthGradientButton(
                                      isLoading: authState.isLoading,
                                      onPressed: _handleRegister,
                                      label: 'Create Account',
                                    ),
                                    const SizedBox(height: 16),

                                    // Muted Terms & Privacy Notice
                                    const Text(
                                      'By continuing, you agree to Kasyaba\'s Terms of Service and Privacy Policy. All financial records are calculated locally with zero AI telemetry.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Sign In Navigation Link ───────
                              Center(
                                child: TextButton(
                                  onPressed: () => context.go('/login'),
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
                                          text: 'Already have an account?  ',
                                          style: TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'Sign In',
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthBackButton extends StatelessWidget {
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xBF0F172A),
              border: Border.all(
                color: const Color(0x14FFFFFF),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
