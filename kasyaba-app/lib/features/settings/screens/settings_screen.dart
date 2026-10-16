import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/app_info.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/ph_salary_calculator.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_text_field.dart';
import '../widgets/data_backup_sheets.dart';

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
  final _deleteAccountPasswordController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    _grossSalaryController.dispose();
    _allowancesController.dispose();
    _minThresholdController.dispose();
    _deleteAccountPasswordController.dispose();
    super.dispose();
  }

  void _showEditProfileBottomSheet(UserProfile profile) {
    // Reset previous input, then seed the sheet from the saved profile.
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

    ModernBottomSheet.show(
      context: context,
      title: 'Salary & Payday Settings',
      subtitle:
          'Feed your exact income schedule into the deterministic forecasting engine.',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Mode Switcher: Direct Net vs Statutory Calculator ──
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppColors.subtleBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () =>
                              setModalState(() => isCalculatorMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: !isCalculatorMode
                                  ? (isDark
                                      ? const Color(0xFF334155)
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: !isCalculatorMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit_note_rounded,
                                  size: 16,
                                  color: !isCalculatorMode
                                      ? const Color(0xFF10B981)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Direct Net Pay',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: !isCalculatorMode
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: !isCalculatorMode
                                        ? (isDark
                                            ? Colors.white
                                            : AppColors.textLight)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setModalState(() {
                              isCalculatorMode = true;
                              recomputeBreakdown();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isCalculatorMode
                                  ? (isDark
                                      ? const Color(0xFF334155)
                                      : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isCalculatorMode
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.12),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calculate_outlined,
                                  size: 16,
                                  color: isCalculatorMode
                                      ? const Color(0xFF38BDF8)
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'PH Statutory Calc',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isCalculatorMode
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isCalculatorMode
                                        ? (isDark
                                            ? Colors.white
                                            : AppColors.textLight)
                                        : Colors.grey,
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
                const SizedBox(height: 16),

                if (!isCalculatorMode) ...[
                  ModernTextField(
                    controller: _salaryController,
                    label: 'Monthly Net Take-Home Salary (₱)',
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
                  const SizedBox(height: 6),
                  Text(
                    'Directly input what lands in your bank or e-wallet every month.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedL,
                    ),
                  ),
                ] else ...[
                  ModernTextField(
                    controller: _grossSalaryController,
                    label: 'Monthly Gross Basic Salary (₱)',
                    hint: '50000.00',
                    prefixIcon: Icons.account_balance_outlined,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setModalState(recomputeBreakdown),
                    validator: (v) {
                      if (isCalculatorMode) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter your gross basic salary';
                        }
                        final val = double.tryParse(v.trim());
                        if (val == null || !val.isFinite || val <= 0) {
                          return 'Enter a valid positive salary';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  ModernTextField(
                    controller: _allowancesController,
                    label: 'Non-Taxable Allowances / De Minimis (₱)',
                    hint: '2000.00 (Optional)',
                    prefixIcon: Icons.card_giftcard_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setModalState(recomputeBreakdown),
                  ),
                  const SizedBox(height: 14),

                  // Payslip Breakdown Card
                  _buildPayslipBreakdownCard(
                    context: context,
                    breakdown: liveBreakdown,
                    paydaySched: paydaySched,
                  ),
                ],
                const SizedBox(height: 18),

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
                    fillColor: isDark
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
                    fillColor: isDark
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

                          final double? finalSalary;
                          if (isCalculatorMode) {
                            final gross = double.tryParse(
                              _grossSalaryController.text.trim(),
                            ) ?? 0.0;
                            final allow = double.tryParse(
                              _allowancesController.text.trim(),
                            ) ?? 0.0;
                            final calc = PhSalaryCalculator.calculate(
                              grossBasicSalary: gross,
                              nonTaxableAllowances: allow,
                            );
                            finalSalary = calc.netMonthlyPay;
                            _salaryController.text =
                                finalSalary.toStringAsFixed(2);
                          } else {
                            finalSalary = double.tryParse(
                              _salaryController.text.trim(),
                            );
                          }

                          final minThresh = double.tryParse(
                            _minThresholdController.text.trim(),
                          );
                          setModalState(() => isSubmitting = true);

                          try {
                            final mutator = ref.read(
                              transactionMutatorProvider,
                            );
                            await mutator.updateProfile(
                              salaryAmount: finalSalary,
                              paydayFrequency: paydayFreq,
                              paydaySchedule: paydaySched,
                              minimumBalanceThreshold: minThresh,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    finalSalary != null
                                        ? 'Salary settings updated! Net: ${CurrencyFormatter.format(finalSalary)}/mo'
                                        : 'Salary & Payday settings updated!',
                                  ),
                                  backgroundColor: const Color(0xFF10B981),
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

  Widget _buildPayslipBreakdownCard({
    required BuildContext context,
    required PhSalaryBreakdown? breakdown,
    required String paydaySched,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (breakdown == null || breakdown.grossBasicSalary <= 0) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.subtleBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: Color(0xFF38BDF8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Enter your Gross Basic Salary to see your official statutory deductions and take-home pay.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMuted : AppColors.textMutedL,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PHILIPPINE PAYSLIP BREAKDOWN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : AppColors.textLight,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'STATUTORY 2026',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x22334155)),
          const SizedBox(height: 10),

          // Earnings
          _payslipRow(
            label: 'Gross Basic Salary',
            amount: breakdown.grossBasicSalary,
            isBold: true,
            color: isDark ? Colors.white : AppColors.textLight,
          ),
          if (breakdown.nonTaxableAllowances > 0) ...[
            const SizedBox(height: 5),
            _payslipRow(
              label: '+ Non-Taxable Allowances',
              amount: breakdown.nonTaxableAllowances,
              color: const Color(0xFF10B981),
            ),
          ],
          const SizedBox(height: 10),

          // Statutory Deductions
          Text(
            'MANDATORY CONTRIBUTIONS & TAXES',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isDark ? AppColors.textMuted : AppColors.textMutedL,
            ),
          ),
          const SizedBox(height: 6),
          _payslipRow(
            label: 'SSS Employee (RA 11199)',
            amount: -breakdown.sssContribution,
            color: AppColors.expense,
          ),
          const SizedBox(height: 5),
          _payslipRow(
            label: 'PhilHealth (2.5% share)',
            amount: -breakdown.philHealthContribution,
            color: AppColors.expense,
          ),
          const SizedBox(height: 5),
          _payslipRow(
            label: 'Pag-IBIG Fund (Standard)',
            amount: -breakdown.pagIbigContribution,
            color: AppColors.expense,
          ),
          const SizedBox(height: 5),
          _payslipRow(
            label: 'TRAIN Withholding Tax',
            amount: -breakdown.withholdingTax,
            color: AppColors.expense,
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0x22334155)),
          const SizedBox(height: 10),

          // Total Deductions
          _payslipRow(
            label: 'Total Monthly Deductions',
            amount: -breakdown.totalDeductions,
            isBold: true,
            color: AppColors.expense,
          ),
          const SizedBox(height: 12),

          // Net Monthly Take-Home Hero Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF064E3B), Color(0xFF022C22)]
                    : const [Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Net Monthly Take-Home',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFA7F3D0)
                            : const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(breakdown.netMonthlyPay),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF064E3B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semi-Monthly ($paydaySched)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textMuted
                            : const Color(0xFF047857),
                      ),
                    ),
                    Text(
                      '${CurrencyFormatter.format(breakdown.semiMonthlyPayout)} / payout',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? const Color(0xFF34D399)
                            : const Color(0xFF065F46),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _payslipRow({
    required String label,
    required double amount,
    bool isBold = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
        Text(
          amount < 0
              ? '- ${CurrencyFormatter.format(amount.abs())}'
              : CurrencyFormatter.format(amount),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          // User Profile Card
          ModernCard(
            padding: const EdgeInsets.all(20),
            borderRadius: 16,
            borderColor: AppColors.subtleBorder,
            backgroundColor: isDark ? AppColors.surface800 : AppColors.lightCard,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surface700 : AppColors.lightCard2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.emerald500,
                      width: 2,
                    ),
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
                          'Monthly Net Pay:',
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
                    if (profile.salaryAmount != null &&
                        profile.salaryAmount! > 0) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            'Estimated Semi-Monthly:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${CurrencyFormatter.format(profile.salaryAmount! / 2)} / payout',
                              textAlign: TextAlign.end,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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
          const SizedBox(height: 24),

          // Data & Backup Management Section Label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'DATA & BACKUP MANAGEMENT',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),

          // Data & Backup Management Card
          ModernCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.cloud_download_outlined,
                    color: Color(0xFF0284C7),
                  ),
                  title: const Text(
                    'Export Backup (JSON)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Complete account & ledger snapshot'),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showExportBackupSheet(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF10B981),
                  ),
                  title: const Text(
                    'Import / Restore Backup (JSON)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Restore financial records with schema check',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showRestoreBackupSheet(context, ref),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(
                    Icons.table_chart_outlined,
                    color: Color(0xFFD4AF37),
                  ),
                  title: const Text(
                    'Export Transactions to CSV',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'RFC 4180 format for Excel & Google Sheets',
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => showExportCsvSheet(context, ref),
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
