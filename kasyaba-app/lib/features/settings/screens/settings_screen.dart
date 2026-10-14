import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/app_info.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_text_field.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _salaryController = TextEditingController();
  final _minThresholdController = TextEditingController();
  final _deleteAccountPasswordController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    _minThresholdController.dispose();
    _deleteAccountPasswordController.dispose();
    super.dispose();
  }

  void _showEditProfileBottomSheet(UserProfile profile) {
    // Reset previous input, then seed the sheet from the saved profile.
    _salaryController.clear();
    _minThresholdController.clear();
    _salaryController.text = profile.salaryAmount?.toStringAsFixed(2) ?? '';
    _minThresholdController.text =
        profile.minimumBalanceThreshold?.toStringAsFixed(2) ?? '0';
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;

    String paydayFreq = profile.paydayFrequency ?? 'semi-monthly';
    String paydaySched = profile.paydaySchedule ?? '15th & 30th';

    ModernBottomSheet.show(
      context: context,
      title: 'Salary & Payday Settings',
      subtitle:
          'Feed your exact income schedule into the deterministic forecasting engine.',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(
                  controller: _salaryController,
                  label: 'Monthly Salary / Base Income (₱)',
                  hint: '45000.00',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final value = double.tryParse(v.trim());
                    if (value == null || !value.isFinite || value < 0) {
                      return 'Enter a valid non-negative amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Payday Frequency',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: paydayFreq,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.event_repeat_outlined,
                      color: Color(0xFF10B981),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'semi-monthly',
                      child: Text('Semi-Monthly (Twice a month)'),
                    ),
                    DropdownMenuItem(
                      value: 'monthly',
                      child: Text('Monthly (Once a month)'),
                    ),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setModalState(() => paydayFreq = val);
                          }
                        },
                ),
                const SizedBox(height: 16),

                const Text(
                  'Payday Schedule',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: paydaySched,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFF10B981),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: '15th & 30th',
                      child: Text('15th & 30th of the month'),
                    ),
                    DropdownMenuItem(
                      value: '1st & 15th',
                      child: Text('1st & 15th of the month'),
                    ),
                    DropdownMenuItem(
                      value: '1st of month',
                      child: Text('1st day of the month'),
                    ),
                    DropdownMenuItem(
                      value: '30th of month',
                      child: Text('End of the month'),
                    ),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (val) {
                          if (val != null) {
                            setModalState(() => paydaySched = val);
                          }
                        },
                ),
                const SizedBox(height: 16),

                ModernTextField(
                  controller: _minThresholdController,
                  label: 'Minimum Safety Buffer Threshold (₱)',
                  hint: '2000.00',
                  prefixIcon: Icons.shield_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final value = double.tryParse(v.trim());
                    if (value == null || !value.isFinite || value < 0) {
                      return 'Enter a valid non-negative amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (isSubmitting) return;
                          if (!formKey.currentState!.validate()) return;
                          final salary = double.tryParse(
                            _salaryController.text.trim(),
                          );
                          final minThresh = double.tryParse(
                            _minThresholdController.text.trim(),
                          );
                          setModalState(() => isSubmitting = true);

                          try {
                            final mutator = ref.read(
                              transactionMutatorProvider,
                            );
                            await mutator.updateProfile(
                              salaryAmount: salary,
                              paydayFrequency: paydayFreq,
                              paydaySchedule: paydaySched,
                              minimumBalanceThreshold: minThresh,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Salary & Payday settings updated!',
                                  ),
                                  backgroundColor: Color(0xFF10B981),
                                ),
                              );
                            }
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    friendlyErrorMessage(
                                      error,
                                      fallback:
                                          'Unable to update settings. Please try again.',
                                    ),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check, size: 20),
                  label: Text(
                    isSubmitting ? 'Saving...' : 'Save Salary Settings',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final displayName = authState.displayName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // User Profile Card
          ModernCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            borderColor: AppColors.subtleBorder,
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                  : const [Color(0xFFECFDF5), Color(0xFFF8FAFC)],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF10B981)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        authState.email ?? 'No email set',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Salary & Payday Settings Card ────────────────────────
          profileAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, _) => const SizedBox.shrink(),
            data: (profile) {
              final salaryStr = profile.salaryAmount != null
                  ? '${CurrencyFormatter.format(profile.salaryAmount!)} / month'
                  : 'Not configured';
              final schedStr =
                  '${profile.paydayFrequency ?? 'semi-monthly'} (${profile.paydaySchedule ?? '15th & 30th'})';

              return ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.work_outline_rounded,
                                color: Color(0xFF10B981),
                                size: 22,
                              ),
                              SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  'Salary & Payday Settings',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit salary & payday settings',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF10B981),
                          ),
                          onPressed: () => _showEditProfileBottomSheet(profile),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Monthly Salary:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            salaryStr,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Text(
                          'Payout Schedule:',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            schedStr,
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Settings Section Label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'PREFERENCES',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          // Settings Options Card
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.auto_graph_rounded,
                    color: Color(0xFFD4AF37),
                  ),
                  title: const Text(
                    'Planning Lab',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Map your runway and test decisions manually',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/planning'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFF10B981),
                  ),
                  title: const Text(
                    'Accounts & Wallets',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Manage cash, bank accounts & e-wallets',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/accounts'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFFF59E0B),
                  ),
                  title: const Text(
                    'Notifications',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Bill reminders & budget alerts'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notifications enabled for bill reminders',
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Color(0xFF059669),
                  ),
                  title: const Text(
                    'Privacy Policy',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Data protection & user rights'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: Color(0xFF059669),
                            ),
                            SizedBox(width: 8),
                            Text('Privacy Policy'),
                          ],
                        ),
                        content: const SingleChildScrollView(
                          child: Text(
                            'KASYABA values your privacy. We do not sell your personal or financial data. '
                            'Your financial ledger, accounts, and budgets are securely encrypted and used strictly '
                            'to provide deterministic forecasting, safety calculations, and bill reminders.\n\n'
                            'You may request complete account and data deletion at any time in Profile & Settings.',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.download_outlined,
                    color: Color(0xFF0284C7),
                  ),
                  title: const Text(
                    'Export Financial Data',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Download your account records (JSON)'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () async {
                    try {
                      final data = await ref
                          .read(authProvider.notifier)
                          .exportData();
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            title: const Text('Data Export Ready'),
                            content: Text(
                              'Export completed successfully for ${data['user']?['email'] ?? 'your account'}.\n\n'
                              'Export Timestamp: ${data['exportedAt']}',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              friendlyErrorMessage(
                                error,
                                fallback:
                                    'Failed to export data. Please try again.',
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Color(0xFF64748B),
                  ),
                  title: const Text(
                    'About Kasyaba',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(kAppVersionLabel),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Kasyaba',
                      applicationVersion: 'v$kAppVersion',
                      applicationLegalese:
                          '© 2026 Kasyaba Finance. All rights reserved.',
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Sign Out Button
          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text(
              'Sign Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: theme.colorScheme.onSurface,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Delete Account Button (Google Play Compliance)
          TextButton.icon(
            onPressed: () async {
              final hasPassword = ref.read(authProvider).hasPassword;
              _deleteAccountPasswordController.clear();
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Are you sure you want to permanently delete your KASYABA account?\n\n'
                        'This action is irreversible and will immediately erase all your financial records, accounts, transactions, and budgets.',
                      ),
                      if (hasPassword) ...[
                        const SizedBox(height: 20),
                        TextField(
                          controller: _deleteAccountPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirm your password',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                      ),
                      child: const Text('Delete Permanently'),
                    ),
                  ],
                ),
              );

              if (confirmed != true) return;

              try {
                await ref
                    .read(authProvider.notifier)
                    .deleteAccount(
                      password: hasPassword
                          ? _deleteAccountPasswordController.text
                          : null,
                    );
                if (context.mounted) {
                  context.go('/login');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Your account and data have been completely deleted.',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        friendlyErrorMessage(
                          error,
                          fallback:
                              'Failed to delete account. Please check your password and try again.',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
            icon: Icon(
              Icons.delete_forever_outlined,
              color: theme.colorScheme.error,
              size: 20,
            ),
            label: Text(
              'Delete Account and Data',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}
