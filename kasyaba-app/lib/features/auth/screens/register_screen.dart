import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final formGroup = FormGroup({
    'name': FormControl<String>(validators: [Validators.required]),
    'email': FormControl<String>(
      validators: [Validators.required, Validators.email],
    ),
    'password': FormControl<String>(
      validators: [Validators.required, Validators.minLength(8)],
    ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AuthFigmaTokens.ebony : AppColors.lightScaffold,
      body: Stack(
        children: [
          // ── Background with exact Figma radial gradients & radar arcs (Node 11:738) ──
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
                            const SizedBox(height: 12),

                            // ── Top Navigation & Step Indicator (Node 11:741-746) ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AuthBackButton(
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/login');
                                    }
                                  },
                                  size: 46,
                                  radius: 22,
                                  backgroundColor: isDark
                                      ? AuthFigmaTokens.cello55
                                      : AppColors.lightCardSurface,
                                  borderColor: isDark
                                      ? AuthFigmaTokens.poloBlue28
                                      : AppColors.lightBorderHairline,
                                  hasBlur: true,
                                ),
                                Text(
                                  'STEP 1 OF 2',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.0,
                                    color: isDark
                                        ? AuthFigmaTokens.poloBlue
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),

                            // ── Title (Node 11:747-750) ──
                            Text(
                              'Create your account.',
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

                            // ── Subtitle (Node 11:751-753) ──
                            Text(
                              'Takes a minute. Then we tailor Kasyaba to you.',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                color: isDark
                                    ? AuthFigmaTokens.poloBlue
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // ── Form Card (Node 11:754-775, width: 342, r: 32) ──
                            AuthFormCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (authState.error != null) ...[
                                    AuthErrorBanner(
                                      message: authState.error!,
                                    ),
                                    const SizedBox(height: 14),
                                  ],

                                  // FULL NAME Field (Node 11:756-761)
                                  AuthReactiveField(
                                    formControlName: 'name',
                                    label: 'Full name',
                                    hintText: 'Juan Dela Cruz',
                                    textInputAction: TextInputAction.next,
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Please enter your name',
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // EMAIL Field (Node 11:762-767)
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

                                  // PASSWORD Field (Node 11:768-773)
                                  AuthReactiveField(
                                    formControlName: 'password',
                                    label: 'Password',
                                    hintText: 'At least 8 characters',
                                    obscureText: true,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: _handleRegister,
                                    validationMessages: {
                                      ValidationMessage.required: (_) =>
                                          'Password is required',
                                      ValidationMessage.minLength: (_) =>
                                          'At least 8 characters required',
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Continue Button (Node 11:774-775, height: 56, r: 28)
                                  AuthPrimaryPillButton(
                                    isLoading: authState.isLoading,
                                    onPressed: _handleRegister,
                                    label: 'Continue',
                                    height: 56,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),

                            // ── Footnote (Node 11:776-778) ──
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
