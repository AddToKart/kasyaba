import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/motion_components.dart';

/// ─────────────────────────────────────────────────────────────
///  1:1 Figma Delete Account Screen (Node 11:1022)
/// ─────────────────────────────────────────────────────────────
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
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
    final typedCorrectly = _confirmationController.text.trim().toUpperCase() == 'DELETE';
    final hasPassword = ref.read(authProvider).hasPassword;
    if (hasPassword) {
      return typedCorrectly && _passwordController.text.isNotEmpty;
    }
    return typedCorrectly;
  }

  Future<void> _handleDelete() async {
    if (!_canDelete || _isDeleting) return;

    setState(() => _isDeleting = true);
    final hasPassword = ref.read(authProvider).hasPassword;

    try {
      await ref.read(authProvider.notifier).deleteAccount(
            password: hasPassword ? _passwordController.text : null,
          );
      if (mounted) {
        context.go('/login');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account and data have been permanently deleted.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                error,
                fallback: 'Failed to delete account. Please check your credentials and try again.',
              ),
            ),
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

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    // Back button row
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
                                color: DashboardTokens.bigStone,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: DashboardTokens.poloBlue22,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: DashboardTokens.periwinkleGray,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Danger Icon & Title
                    FadeSlideEntrance.staggered(
                      index: 1,
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: DashboardTokens.apricot15,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.warning_amber_rounded,
                                color: DashboardTokens.apricot,
                                size: 36,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Delete everything?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Warning Card
                    FadeSlideEntrance.staggered(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'This permanently deletes:',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: DashboardTokens.periwinkleGray,
                                height: 1.45,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• Your account and profile\n• All transactions, goals, bills and budgets\n• Every account and wallet',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: DashboardTokens.periwinkleGray,
                                height: 1.6,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'This cannot be undone. Back up first if you may want it later.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: DashboardTokens.apricot,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // "Back up first" Button
                    FadeSlideEntrance.staggered(
                      index: 3,
                      child: SpringTouch(
                        onTap: () => context.push('/settings/backup'),
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: DashboardTokens.kashmirBlue,
                              width: 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Back up first',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Confirmation Pill Input ("Type DELETE")
                    FadeSlideEntrance.staggered(
                      index: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 80,
                              child: Text(
                                'Type',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _confirmationController,
                                onChanged: (_) => setState(() {}),
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.periwinkleGray,
                                  letterSpacing: 1.0,
                                ),
                                decoration: const InputDecoration(
                                  hintText: 'DELETE',
                                  hintStyle: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.poloBlue40,
                                    letterSpacing: 1.0,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (hasPassword) ...[
                      const SizedBox(height: 14),
                      FadeSlideEntrance.staggered(
                        index: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 6),
                          decoration: BoxDecoration(
                            color: DashboardTokens.bigStone,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: DashboardTokens.poloBlue22,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 80,
                                child: Text(
                                  'Password',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Your password',
                                    hintStyle: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 15,
                                      color: DashboardTokens.poloBlue40,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Danger CTA Button
                    FadeSlideEntrance.staggered(
                      index: hasPassword ? 6 : 5,
                      child: Opacity(
                        opacity: _canDelete && !_isDeleting ? 1.0 : 0.45,
                        child: SpringTouch(
                          onTap: _canDelete && !_isDeleting ? _handleDelete : null,
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: DashboardTokens.apricot,
                                width: 1,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: _isDeleting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(DashboardTokens.apricot),
                                    ),
                                  )
                                : const Text(
                                    'Delete account and data',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: DashboardTokens.apricot,
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
        ),
      ),
    );
  }
}
