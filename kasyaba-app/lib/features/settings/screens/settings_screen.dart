import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/api_providers.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_text_field.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showEditProfileBottomSheet(BuildContext context, WidgetRef ref, UserProfile profile) {
    final salaryController = TextEditingController(
      text: profile.salaryAmount != null ? profile.salaryAmount!.toStringAsFixed(2) : '',
    );
    final minThresholdController = TextEditingController(
      text: profile.minimumBalanceThreshold != null ? profile.minimumBalanceThreshold!.toStringAsFixed(2) : '0',
    );
    final formKey = GlobalKey<FormState>();

    String paydayFreq = profile.paydayFrequency ?? 'semi-monthly';
    String paydaySched = profile.paydaySchedule ?? '15th & 30th';

    ModernBottomSheet.show(
      context: context,
      title: 'Salary & Payday Settings 💼',
      subtitle: 'Feed your exact income schedule into the deterministic forecasting engine.',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(
                  controller: salaryController,
                  label: 'Monthly Salary / Base Income (₱)',
                  hint: '45000.00',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    prefixIcon: const Icon(Icons.event_repeat_outlined, color: Color(0xFF10B981)),
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
                    DropdownMenuItem(value: 'semi-monthly', child: Text('Semi-Monthly (Twice a month)')),
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly (Once a month)')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => paydayFreq = val);
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
                    prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF10B981)),
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
                    DropdownMenuItem(value: '15th & 30th', child: Text('15th & 30th of the month')),
                    DropdownMenuItem(value: '1st & 15th', child: Text('1st & 15th of the month')),
                    DropdownMenuItem(value: '1st of month', child: Text('1st day of the month')),
                    DropdownMenuItem(value: '30th of month', child: Text('End of the month')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => paydaySched = val);
                  },
                ),
                const SizedBox(height: 16),

                ModernTextField(
                  controller: minThresholdController,
                  label: 'Minimum Safety Buffer Threshold (₱)',
                  hint: '2000.00',
                  prefixIcon: Icons.shield_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final salary = double.tryParse(salaryController.text.trim());
                    final minThresh = double.tryParse(minThresholdController.text.trim());

                    final mutator = ref.read(transactionMutatorProvider);
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
                          content: Text('Salary & Payday settings updated! 💼'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Save Salary Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final displayName = authState.displayName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // User Profile Card
          ModernCard(
            padding: const EdgeInsets.all(20),
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                  : const [Color(0xFFECFDF5), Color(0xFFF8FAFC)],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
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
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authState.email ?? 'No email set',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
                  ? '₱${profile.salaryAmount!.toStringAsFixed(2)} / month'
                  : 'Not configured';
              final schedStr = '${profile.paydayFrequency ?? 'semi-monthly'} (${profile.paydaySchedule ?? '15th & 30th'})';

              return ModernCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.work_outline_rounded, color: Color(0xFF10B981), size: 22),
                            SizedBox(width: 10),
                            Text(
                              'Salary & Payday Settings',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF10B981)),
                          onPressed: () => _showEditProfileBottomSheet(context, ref, profile),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Salary:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          salaryStr,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payout Schedule:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text(
                          schedStr,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                  leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF10B981)),
                  title: const Text('Accounts & Wallets', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Manage cash, bank accounts & e-wallets'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: Color(0xFF3B82F6)),
                  title: const Text('Categories', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Customize income and expense categories'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: Color(0xFFF59E0B)),
                  title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Bill reminders & budget alerts'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notifications enabled for bill reminders')),
                    );
                  },
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6)),
                  title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('System / Light / Dark theme'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () {},
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFF64748B)),
                  title: const Text('About Kasyaba', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Version 0.1.0 (Build 1)'),
                  onTap: () {},
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
            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
