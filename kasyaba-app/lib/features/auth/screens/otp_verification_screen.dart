import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/kasyaba_color_scheme.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../widgets/auth_widgets.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _expiryTimer;
  Timer? _cooldownTimer;

  int _expirySeconds = 600; // 10 minutes
  int _cooldownSeconds = 60; // 60s cooldown for resending
  String? _localError;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _startTimers() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_expirySeconds <= 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _expirySeconds--;
          });
        }
      }
    });

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 0) {
        timer.cancel();
      } else {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _cooldownTimer?.cancel();
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _localError = 'Please enter all 6 digits.';
      });
      return;
    }

    if (_expirySeconds <= 0) {
      setState(() {
        _localError =
            'Verification code has expired. Please request a new one.';
      });
      return;
    }

    setState(() {
      _localError = null;
    });

    try {
      final resetToken = await ref
          .read(authProvider.notifier)
          .verifyOtp(email: widget.email, otp: otp);

      if (!mounted) return;

      context.push(
        '/new-password',
        extra: {'email': widget.email, 'resetToken': resetToken},
      );
    } catch (_) {
      // Error is set in AuthState or caught locally
      if (mounted) {
        setState(() {
          _localError =
              ref.read(authProvider).error ??
              'Invalid verification code. Please check and try again.';
          _otpController.clear();
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _localError = null;
    });

    try {
      await ref.read(authProvider.notifier).requestPasswordReset(widget.email);
      if (!mounted) return;

      setState(() {
        _expirySeconds = 600;
        _cooldownSeconds = 60;
        _otpController.clear();
      });
      _startTimers();

      KasyabaToast.showSuccess(
        context,
        'New code sent! Check your email inbox.',
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _localError = 'Failed to resend code. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
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
    final colors = context.kColors;

    final errorMessage = _localError ?? authState.error;
    final currentCode = _otpController.text;

    return Scaffold(
      backgroundColor: colors.canvas,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AuthBackButton(onPressed: _handleBack),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Verification Code',
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.w700,
                                fontSize: 32,
                                height: 1.1,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter the 6-digit code sent to ${widget.email}.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Form Card matching Login Screen ──
                            AuthFormCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (errorMessage != null) ...[
                                    AuthErrorBanner(message: errorMessage),
                                    const SizedBox(height: 14),
                                  ],

                                  // ── 6-Digit Code Display with Hidden Real Input ──
                                  GestureDetector(
                                    onTap: () => _focusNode.requestFocus(),
                                    behavior: HitTestBehavior.opaque,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Invisible TextField capturing keyboard input
                                        Opacity(
                                          opacity: 0.0,
                                          child: TextField(
                                            controller: _otpController,
                                            focusNode: _focusNode,
                                            keyboardType: TextInputType.number,
                                            maxLength: 6,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                6,
                                              ),
                                            ],
                                            onChanged: (val) {
                                              setState(() {});
                                              if (val.length == 6) {
                                                _handleVerify();
                                              }
                                            },
                                          ),
                                        ),

                                        // Row of 6 Digit Squircle Cells
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: List.generate(6, (index) {
                                            final isFilled =
                                                index < currentCode.length;
                                            final isCurrent =
                                                index == currentCode.length &&
                                                _focusNode.hasFocus;
                                            final digit = isFilled
                                                ? currentCode[index]
                                                : '';

                                            return AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 150,
                                              ),
                                              width: 44,
                                              height: 52,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? (isCurrent
                                                          ? colors.cardHero
                                                                .withValues(
                                                                  alpha: 0.55,
                                                                )
                                                          : colors.canvas
                                                                .withValues(
                                                                  alpha: 0.55,
                                                                ))
                                                    : colors.card,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: isCurrent
                                                      ? colors.success
                                                      : (isFilled
                                                            ? (isDark
                                                                  ? colors.icon
                                                                        .withValues(
                                                                          alpha:
                                                                              0.35,
                                                                        )
                                                                  : colors
                                                                        .cardBorderStrong)
                                                            : colors
                                                                  .inputBorder),
                                                  width: isCurrent ? 2.0 : 1.2,
                                                ),
                                                boxShadow: isCurrent
                                                    ? [
                                                        BoxShadow(
                                                          color: colors.success
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          blurRadius: 8,
                                                          spreadRadius: 1,
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Text(
                                                digit,
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w700,
                                                  color: isDark && isFilled
                                                      ? colors.success
                                                      : colors.textPrimary,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Expiry countdown indicator ──
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 16,
                                        color: _expirySeconds <= 60
                                            ? colors.danger
                                            : colors.textSecondary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _expirySeconds > 0
                                            ? 'Code expires in ${_formatDuration(_expirySeconds)}'
                                            : 'Code expired',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: _expirySeconds <= 60
                                              ? colors.danger
                                              : colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Resend Code Section ──
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        "Didn't receive code? ",
                                        style: GoogleFonts.dmSans(
                                          color: colors.textSecondary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap:
                                            (_cooldownSeconds == 0 &&
                                                !_isResending)
                                            ? _handleResend
                                            : null,
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                            bottom: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              bottom: BorderSide(
                                                color: _cooldownSeconds == 0
                                                    ? colors.secondaryBorder
                                                    : Colors.transparent,
                                                width: 1.5,
                                              ),
                                            ),
                                          ),
                                          child: _isResending
                                              ? SizedBox(
                                                  height: 14,
                                                  width: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 1.8,
                                                        color: colors.success,
                                                      ),
                                                )
                                              : Text(
                                                  _cooldownSeconds > 0
                                                      ? 'Resend (${_cooldownSeconds}s)'
                                                      : 'Resend code',
                                                  style: GoogleFonts.dmSans(
                                                    color: _cooldownSeconds > 0
                                                        ? (isDark
                                                              ? colors.icon
                                                                    .withValues(
                                                                      alpha:
                                                                          0.28,
                                                                    )
                                                              : colors
                                                                    .textSecondary)
                                                        : colors.textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // ── Primary Pill Button ──
                                  AuthPrimaryPillButton(
                                    isLoading: authState.isLoading,
                                    onPressed: _handleVerify,
                                    label: 'Verify code',
                                  ),
                                ],
                              ),
                            ),
                          ],
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
