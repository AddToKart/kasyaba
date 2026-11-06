import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/database/cache_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmationController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _canDelete {
    final typedCorrectly =
        _confirmationController.text.trim().toUpperCase() == 'DELETE';
    final hasPassword = ref.read(authProvider).hasPassword;
    if (hasPassword) {
      return typedCorrectly && _passwordController.text.isNotEmpty;
    }
    return typedCorrectly;
  }

  Future<void> _handleDelete() async {
    if (!_canDelete || _isDeleting) return;
    if (!ref.read(isOnlineProvider)) {
      KasyabaToast.showError(
        context,
        'Deleting your account needs an internet connection.',
      );
      return;
    }

    setState(() => _isDeleting = true);
    final hasPassword = ref.read(authProvider).hasPassword;
    final userId = ref.read(authProvider).userId;

    try {
      await ref
          .read(authProvider.notifier)
          .deleteAccount(
            password: hasPassword ? _passwordController.text : null,
          );
      if (userId != null) {
        // Server deletion succeeded: wipe this device's snapshots and queue
        // too. Local cleanup is best effort and must not mask the success.
        try {
          await ref.read(cacheServiceProvider).deleteAllForUser(userId);
        } catch (_) {}
      }
      if (mounted) {
        KasyabaToast.showSuccess(
          context,
          'Your account and data have been permanently deleted.',
        );
        context.go('/login');
      }
    } catch (error) {
      if (mounted) {
        KasyabaToast.showError(
          context,
          friendlyErrorMessage(
            error,
            fallback:
                'Failed to delete account. Please check your credentials and try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = ref.watch(authProvider).hasPassword;
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: KasyabaTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(gradient: KasyabaTokens.canvasGradient),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              KasyabaTokens.dockClearance,
            ),
            children: [
              FadeSlideEntrance.staggered(
                index: 0,
                child: Row(
                  children: [
                    SpringTouch(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: KasyabaTokens.bigStone,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: KasyabaTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: KasyabaTokens.periwinkleGray,
                          size: 26,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideEntrance.staggered(
                index: 1,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: KasyabaTokens.apricot15,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: KasyabaTokens.apricot,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Delete everything?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FadeSlideEntrance.staggered(
                index: 2,
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.bigStone,
                    borderRadius: BorderRadius.circular(
                      KasyabaTokens.radiusCard,
                    ),
                    border: Border.all(
                      color: KasyabaTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This permanently deletes:',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KasyabaTokens.periwinkleGray,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Your account and profile\n• All transactions, goals, bills and budgets\n• Every account and wallet',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KasyabaTokens.periwinkleGray,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'This cannot be undone. Back up first if you may want it later.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KasyabaTokens.apricot,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 3,
                child: PillButton(
                  label: 'Back up first',
                  variant: PillButtonVariant.secondary,
                  onPressed: () => context.push('/settings/backup'),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 4,
                child: _DeleteField(
                  label: 'Type',
                  child: TextField(
                    controller: _confirmationController,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: KasyabaTokens.periwinkleGray,
                      letterSpacing: 1.0,
                    ),
                    decoration: InputDecoration(
                      hintText: 'DELETE',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.poloBlue40,
                        letterSpacing: 1.0,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              if (hasPassword) ...[
                const SizedBox(height: 14),
                FadeSlideEntrance.staggered(
                  index: 5,
                  child: _DeleteField(
                    label: 'Password',
                    child: TextField(
                      controller: _passwordController,
                      obscureText: true,
                      onChanged: (_) => setState(() {}),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        hintStyle: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: KasyabaTokens.poloBlue40,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (!isOnline) ...[
                const NeedsInternetNotice(
                  message:
                      'Deleting your account needs an internet connection so the server can erase your data.',
                ),
                const SizedBox(height: 14),
              ],
              FadeSlideEntrance.staggered(
                index: hasPassword ? 6 : 5,
                child: PillButton(
                  label: 'Delete account and data',
                  variant: PillButtonVariant.destructive,
                  isLoading: _isDeleting,
                  onPressed: isOnline && _canDelete && !_isDeleting
                      ? _handleDelete
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteField extends StatelessWidget {
  final String label;
  final Widget child;

  const _DeleteField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
      decoration: BoxDecoration(
        color: KasyabaTokens.bigStone,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
        border: Border.all(color: KasyabaTokens.poloBlue22, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KasyabaTokens.periwinkleGraySubtitle,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
