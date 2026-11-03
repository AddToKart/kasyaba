import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/app_info.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/ph_salary_calculator.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/motion_components.dart';

/// ─────────────────────────────────────────────────────────────
///  1:1 Figma Profile & Settings Screen (Node 42:6828)
/// ─────────────────────────────────────────────────────────────
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _salaryController = TextEditingController();
  final _grossSalaryController = TextEditingController();
  final _allowancesController = TextEditingController();
  final _minThresholdController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    _grossSalaryController.dispose();
    _allowancesController.dispose();
    _minThresholdController.dispose();
    super.dispose();
  }

  void _showEditProfileBottomSheet(UserProfile profile) {
    _salaryController.clear();
    _grossSalaryController.clear();
    _allowancesController.clear();
    _minThresholdController.clear();

    _salaryController.text = profile.salaryAmount?.toStringAsFixed(2) ?? '';
    _minThresholdController.text =
        profile.minimumBalanceThreshold?.toStringAsFixed(2) ?? '0';
    final formKey = GlobalKey<FormState>();
    var isSubmitting = false;
    var isCalculatorMode = false;
    PhSalaryBreakdown? liveBreakdown;

    String paydayFreq = profile.paydayFrequency ?? 'semi-monthly';
    String paydaySched = profile.paydaySchedule ?? '15th & 30th';

    void recomputeBreakdown() {
      final gross = double.tryParse(_grossSalaryController.text.trim()) ?? 0.0;
      final allow = double.tryParse(_allowancesController.text.trim()) ?? 0.0;
      liveBreakdown = PhSalaryCalculator.calculate(
        grossBasicSalary: gross,
        nonTaxableAllowances: allow,
      );
    }

    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;

          return Container(
            decoration: BoxDecoration(
              color: DashboardTokens.ebony,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: DashboardTokens.poloBlue22,
                width: 1,
              ),
            ),
            padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: DashboardTokens.poloBlue30,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Salary & Payday Settings',
                      style: TextStyle(
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: DashboardTokens.periwinkleGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Feed your exact income schedule into the deterministic forecasting engine.',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 14,
                        color: DashboardTokens.periwinkleGraySubtitle,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Mode Switcher Pill
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: DashboardTokens.bigStone,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DashboardTokens.poloBlue22,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SpringTouch(
                              onTap: () => setModalState(() => isCalculatorMode = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: !isCalculatorMode
                                      ? DashboardTokens.periwinkleGray
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Direct Net Pay',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: !isCalculatorMode
                                        ? DashboardTokens.ebony
                                        : DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: SpringTouch(
                              onTap: () {
                                setModalState(() {
                                  isCalculatorMode = true;
                                  recomputeBreakdown();
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCalculatorMode
                                      ? DashboardTokens.periwinkleGray
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'PH Statutory Calc',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isCalculatorMode
                                        ? DashboardTokens.ebony
                                        : DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!isCalculatorMode) ...[
                      // Monthly Net Salary Input Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                          controller: _salaryController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Monthly Net Take-Home Salary',
                            labelStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Gross Basic Salary Input Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                          controller: _grossSalaryController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setModalState(recomputeBreakdown),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Monthly Gross Basic Salary',
                            labelStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Non-taxable Allowances Input Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: TextFormField(
                          controller: _allowancesController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setModalState(recomputeBreakdown),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Non-Taxable Allowances',
                            labelStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                      ),
                      if (liveBreakdown != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: DashboardTokens.bigStone,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: DashboardTokens.poloBlue22),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ESTIMATED NET PAYSLIP (PH 2026)',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Computed Net Pay:',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      color: DashboardTokens.periwinkleGraySubtitle,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(liveBreakdown!.netMonthlyPay),
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      color: DashboardTokens.bermuda,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 12),

                    // Payday Frequency Dropdown Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: DashboardTokens.bigStone,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DashboardTokens.poloBlue22,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: paydayFreq,
                          dropdownColor: DashboardTokens.bigStone,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'semi-monthly',
                              child: Text('Semi-monthly (Twice a month)'),
                            ),
                            DropdownMenuItem(
                              value: 'monthly',
                              child: Text('Monthly (Once a month)'),
                            ),
                            DropdownMenuItem(
                              value: 'weekly',
                              child: Text('Weekly (Every 7 days)'),
                            ),
                            DropdownMenuItem(
                              value: 'bi-weekly',
                              child: Text('Bi-weekly (Every 14 days)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => paydayFreq = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Payday Schedule Dropdown Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: DashboardTokens.bigStone,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: DashboardTokens.poloBlue22,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: paydaySched,
                          dropdownColor: DashboardTokens.bigStone,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: DashboardTokens.periwinkleGray,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '15th & 30th',
                              child: Text('15th & 30th (Standard PH)'),
                            ),
                            DropdownMenuItem(
                              value: '10th & 25th',
                              child: Text('10th & 25th'),
                            ),
                            DropdownMenuItem(
                              value: 'End of Month',
                              child: Text('End of Month (Last working day)'),
                            ),
                            DropdownMenuItem(
                              value: 'Custom / Other',
                              child: Text('Custom / Other'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) setModalState(() => paydaySched = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    SpringTouch(
                      onTap: isSubmitting
                          ? null
                          : () async {
                              double? finalSalary;
                              if (isCalculatorMode && liveBreakdown != null) {
                                finalSalary = liveBreakdown!.netMonthlyPay;
                              } else {
                                finalSalary = double.tryParse(_salaryController.text.trim());
                              }

                              final threshold = double.tryParse(_minThresholdController.text.trim()) ?? 0.0;

                              setModalState(() => isSubmitting = true);
                              try {
                                await ref.read(transactionMutatorProvider).updateProfile(
                                      salaryAmount: finalSalary,
                                      paydayFrequency: paydayFreq,
                                      paydaySchedule: paydaySched,
                                      minimumBalanceThreshold: threshold,
                                    );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                              } catch (e) {
                                if (sheetContext.mounted) {
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    SnackBar(content: Text('Error updating settings: $e')),
                                  );
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: DashboardTokens.periwinkleGray,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        alignment: Alignment.center,
                        child: isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(DashboardTokens.ebony),
                                ),
                              )
                            : const Text(
                                'Save settings',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.ebony,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPrivacyPolicySheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: DashboardTokens.ebony,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: DashboardTokens.poloBlue22,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: DashboardTokens.poloBlue30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kasyaba is built offline-first. Your financial records, accounts, goals, and bills remain encrypted on your device.\n\n'
              'We never sell your personal data or track your financial activity. You can export or delete your data at any time.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: DashboardTokens.periwinkleGraySubtitle,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SpringTouch(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: DashboardTokens.periwinkleGray,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DashboardTokens.ebony,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: DashboardTokens.ebony,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: DashboardTokens.poloBlue22,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: DashboardTokens.poloBlue30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'About Kasyaba',
              style: TextStyle(
                fontFamily: 'Bricolage Grotesque',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: DashboardTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Version $kAppVersionLabel\n'
              'Deterministic personal finance for Filipinos.\n\n'
              '© 2026 Kasyaba Finance. All rights reserved.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 14,
                color: DashboardTokens.periwinkleGraySubtitle,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SpringTouch(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: DashboardTokens.periwinkleGray,
                  borderRadius: BorderRadius.circular(26),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'Got it',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: DashboardTokens.ebony,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentThemeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(userProfileProvider);

    final displayName = authState.displayName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              // Header title
              FadeSlideEntrance.staggered(
                index: 0,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Profile',
                    style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Profile Hero Card
              FadeSlideEntrance.staggered(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: DashboardTokens.cello60,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue30,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar & Name Row
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: const BoxDecoration(
                              color: DashboardTokens.periwinkleGray,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                initial,
                                style: const TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.ebony,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontFamily: 'Bricolage Grotesque',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  authState.email ?? 'No email set',
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Tags Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: DashboardTokens.poloBlue40,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              'Full-time employee',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: DashboardTokens.poloBlue40,
                                width: 1,
                              ),
                            ),
                            child: const Text(
                              '25–34',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Salary and payday Card
              FadeSlideEntrance.staggered(
                index: 2,
                child: profileAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => const SizedBox.shrink(),
                  data: (profile) {
                    final salary = profile.salaryAmount ?? 45000.0;
                    final halfSalary = salary / 2;
                    final sched = profile.paydaySchedule ?? '15th and 30th';

                    return Container(
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
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Salary and payday',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.periwinkleGray,
                                ),
                              ),
                              Tooltip(
                                message: 'Edit salary & payday settings',
                                child: SpringTouch(
                                  onTap: () => _showEditProfileBottomSheet(profile),
                                  child: const Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: DashboardTokens.periwinkleGraySubtitle,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${CurrencyFormatter.format(salary)} ',
                                style: const TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: DashboardTokens.periwinkleGray,
                                ),
                              ),
                              const Text(
                                'per month',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Paid on the $sched · ${CurrencyFormatter.format(halfSalary)} each',
                            style: const TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Section Header: MONEY
              FadeSlideEntrance.staggered(
                index: 3,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'MONEY',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // MONEY Card: Accounts, Budgets, Notifications
              FadeSlideEntrance.staggered(
                index: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Accounts and wallets
                      SpringTouch(
                        onTap: () => context.push('/accounts'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Accounts and wallets',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Cash, bank and e-wallets',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 1, color: DashboardTokens.poloBlue16),

                      // Budgets
                      SpringTouch(
                        onTap: () => context.push('/budgets'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Budgets',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Over budget this month',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 1, color: DashboardTokens.poloBlue16),

                      // Notifications
                      SpringTouch(
                        onTap: () => context.push('/settings/notifications'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Notifications',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Bill reminders and budget alerts',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Section Header: YOUR DATA
              FadeSlideEntrance.staggered(
                index: 5,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'YOUR DATA',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // YOUR DATA Card: Backup and export, Privacy policy, About Kasyaba
              FadeSlideEntrance.staggered(
                index: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
                  decoration: BoxDecoration(
                    color: DashboardTokens.bigStone,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: DashboardTokens.poloBlue22,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Backup and export
                      SpringTouch(
                        onTap: () => context.push('/settings/backup'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Backup and export',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'JSON backup, restore, CSV for Excel',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 1, color: DashboardTokens.poloBlue16),

                      // Privacy policy
                      SpringTouch(
                        onTap: _showPrivacyPolicySheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Privacy policy',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Your data stays on your device',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 1, color: DashboardTokens.poloBlue16),

                      // About Kasyaba
                      SpringTouch(
                        onTap: _showAboutSheet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'About Kasyaba',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Version $kAppVersionLabel',
                                      style: TextStyle(
                                        fontFamily: 'DM Sans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Appearance & Theme Card (Allows Theme Switching seamlessly)
              FadeSlideEntrance.staggered(
                index: 7,
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
                    children: [
                      const Text(
                        'Appearance & Theme',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: DashboardTokens.periwinkleGray,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Choose your lighting atmosphere',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: DashboardTokens.periwinkleGraySubtitle,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _buildThemeOption(
                            label: 'Dark',
                            icon: Icons.dark_mode_rounded,
                            isSelected: currentThemeMode == ThemeMode.dark,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark),
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOption(
                            label: 'Light',
                            icon: Icons.light_mode_rounded,
                            isSelected: currentThemeMode == ThemeMode.light,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light),
                          ),
                          const SizedBox(width: 8),
                          _buildThemeOption(
                            label: 'System',
                            icon: Icons.brightness_auto_rounded,
                            isSelected: currentThemeMode == ThemeMode.system,
                            onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign out Button
              FadeSlideEntrance.staggered(
                index: 8,
                child: SpringTouch(
                  onTap: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
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
                      'Sign out',
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

              // Delete account and data Danger text button
              FadeSlideEntrance.staggered(
                index: 9,
                child: Center(
                  child: SpringTouch(
                    onTap: () => context.push('/settings/delete-account'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: Text(
                        'Delete account and data',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontSize: 14,
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
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: SpringTouch(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? DashboardTokens.periwinkleGray : DashboardTokens.ebony,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.transparent : DashboardTokens.poloBlue22,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? DashboardTokens.ebony : DashboardTokens.periwinkleGraySubtitle,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? DashboardTokens.ebony : DashboardTokens.periwinkleGraySubtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
