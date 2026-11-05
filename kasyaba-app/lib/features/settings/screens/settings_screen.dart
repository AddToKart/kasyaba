import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/app_info.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/ph_salary_calculator.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _salaryController = TextEditingController();
  final _grossSalaryController = TextEditingController();
  final _allowancesController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    _grossSalaryController.dispose();
    _allowancesController.dispose();
    super.dispose();
  }

  double _perPaycheck(double monthlySalary, String? frequency) {
    switch ((frequency ?? 'semi-monthly').toLowerCase()) {
      case 'monthly':
        return monthlySalary;
      case 'weekly':
        return monthlySalary * 12 / 52;
      case 'bi-weekly':
        return monthlySalary * 12 / 26;
      case 'semi-monthly':
      default:
        return monthlySalary / 2;
    }
  }

  String _budgetSubtitle(AsyncValue<BudgetStatus> statusAsync) {
    final status = statusAsync.valueOrNull;
    if (status == null || status.budgetCount == 0) {
      return 'View budget status';
    }
    if (status.overallPercent >= 100) {
      return 'Over budget this month';
    }
    return '${status.overallPercent.round()}% of budget used this month';
  }

  void _showSalarySheet(UserProfile profile) {
    _salaryController.clear();
    _grossSalaryController.clear();
    _allowancesController.clear();
    final isOnline = ref.read(isOnlineProvider);

    _salaryController.text = profile.salaryAmount?.toStringAsFixed(2) ?? '';
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

    showKasyabaSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

          return AppSheet(
            color: KasyabaTokens.ebony,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24 + bottomInset),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Salary & Payday Settings',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: KasyabaTokens.periwinkleGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Set your salary and payout schedule so Kasyaba can accurately compute your daily safe-to-spend and forecast your money.',
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: KasyabaTokens.periwinkleGraySubtitle,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SlidingSegmentedPill(
                    items: const ['Direct Net Pay', 'PH Statutory Calc'],
                    selectedIndex: isCalculatorMode ? 1 : 0,
                    height: 52,
                    borderRadius: 26,
                    pillRadius: 22,
                    backgroundColor: KasyabaTokens.bigStone,
                    activeColor: KasyabaTokens.periwinkleGray,
                    activeTextColor: KasyabaTokens.ebony,
                    inactiveTextColor: KasyabaTokens.periwinkleGraySubtitle,
                    fontSize: 13,
                    onChanged: (index) {
                      AppHaptics.selectionClick();
                      setModalState(() {
                        isCalculatorMode = index == 1;
                        if (isCalculatorMode) {
                          recomputeBreakdown();
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      !isCalculatorMode
                          ? 'Enter the actual take-home pay deposited into your account each month.'
                          : 'Enter your basic salary before deductions. Kasyaba will automatically compute PH SSS, PhilHealth, Pag-IBIG, and tax deductions.',
                      key: ValueKey(isCalculatorMode),
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: KasyabaTokens.periwinkleGraySubtitle,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: !isCalculatorMode
                          ? KeyedSubtree(
                              key: const ValueKey('direct_mode'),
                              child: _sheetInputField(
                                label: 'Monthly Net Take-Home Salary',
                                controller: _salaryController,
                                hint: '0.00',
                              ),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('calculator_mode'),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sheetInputField(
                                    label: 'Monthly Gross Basic Salary',
                                    controller: _grossSalaryController,
                                    hint: '0.00',
                                    onChanged: (_) =>
                                        setModalState(recomputeBreakdown),
                                  ),
                                  const SizedBox(height: 14),
                                  _sheetInputField(
                                    label: 'Non-Taxable Allowances',
                                    controller: _allowancesController,
                                    hint: '0.00',
                                    onChanged: (_) =>
                                        setModalState(recomputeBreakdown),
                                  ),
                                  if (liveBreakdown != null) ...[
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.all(19),
                                      decoration: BoxDecoration(
                                        color: KasyabaTokens.cello60,
                                        borderRadius: BorderRadius.circular(
                                          KasyabaTokens.radiusCard,
                                        ),
                                        border: Border.all(
                                          color: KasyabaTokens.poloBlue30,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ESTIMATED NET PAYSLIP (PH 2026)',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: KasyabaTokens
                                                  .periwinkleGraySubtitle,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Text(
                                                'Computed Net Pay:',
                                                style: GoogleFonts.dmSans(
                                                  fontSize: 14,
                                                  color: KasyabaTokens
                                                      .periwinkleGraySubtitle,
                                                ),
                                              ),
                                              Text(
                                                CurrencyFormatter.format(
                                                  liveBreakdown!.netMonthlyPay,
                                                ),
                                                style: GoogleFonts
                                                    .bricolageGrotesque(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      KasyabaTokens.bermuda,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          _buildBreakdownItem(
                                            'Gross Basic',
                                            liveBreakdown!.grossBasicSalary,
                                          ),
                                          _buildBreakdownItem(
                                            'SSS Contribution',
                                            -liveBreakdown!.sssContribution,
                                          ),
                                          _buildBreakdownItem(
                                            'PhilHealth',
                                            -liveBreakdown!
                                                .philHealthContribution,
                                          ),
                                          _buildBreakdownItem(
                                            'Pag-IBIG',
                                            -liveBreakdown!
                                                .pagIbigContribution,
                                          ),
                                          _buildBreakdownItem(
                                            'Withholding Tax',
                                            -liveBreakdown!.withholdingTax,
                                          ),
                                          if (liveBreakdown!
                                                  .nonTaxableAllowances >
                                              0)
                                            _buildBreakdownItem(
                                              'Allowances',
                                              liveBreakdown!
                                                  .nonTaxableAllowances,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sheetDropdown(
                    label: 'Payout Frequency',
                    value: paydayFreq,
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
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => paydayFreq = value);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  _sheetDropdown(
                    label: 'Payout Schedule',
                    value: paydaySched,
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
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => paydaySched = value);
                      }
                    },
                  ),
                    const SizedBox(height: 20),
                    if (!isOnline) ...[
                      const NeedsInternetNotice(
                        message:
                            'Saving salary and payday settings needs an internet connection.',
                      ),
                      const SizedBox(height: 12),
                    ],
                     PillButton(
                      label: 'Save settings',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting || !isOnline
                          ? null
                          : () async {
                              final double? finalSalary;
                              if (isCalculatorMode) {
                                final gross = double.tryParse(
                                  _grossSalaryController.text.trim(),
                                );
                                if (gross == null || gross <= 0) {
                                  KasyabaToast.showError(
                                    sheetContext,
                                    'Enter a monthly gross basic salary greater than zero.',
                                  );
                                  return;
                                }
                                recomputeBreakdown();
                                finalSalary = liveBreakdown!.netMonthlyPay;
                              } else {
                                finalSalary = double.tryParse(
                                  _salaryController.text.trim(),
                                );
                                if (finalSalary == null || finalSalary <= 0) {
                                  KasyabaToast.showError(
                                    sheetContext,
                                    'Enter your monthly net salary.',
                                  );
                                  return;
                                }
                              }

                              setModalState(() => isSubmitting = true);
                              try {
                                await ref
                                    .read(transactionMutatorProvider)
                                    .updateProfile(
                                      salaryAmount: finalSalary,
                                      paydayFrequency: paydayFreq,
                                      paydaySchedule: paydaySched,
                                    );
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                                if (mounted) {
                                  KasyabaToast.showSuccess(
                                    context,
                                    'Salary settings updated.',
                                  );
                                }
                              } catch (error) {
                                if (sheetContext.mounted) {
                                  KasyabaToast.showError(
                                    sheetContext,
                                    friendlyErrorMessage(
                                      error,
                                      fallback:
                                          'Could not update your salary settings. Please try again.',
                                    ),
                                  );
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

  Widget _sheetTextInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: KasyabaTokens.periwinkleGraySubtitle,
            ),
          ),
        ),
        TextField(
          controller: controller,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: KasyabaTokens.periwinkleGray,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 15,
              color: KasyabaTokens.poloBlue40,
            ),
            filled: true,
            fillColor: KasyabaTokens.bigStone,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(
                color: KasyabaTokens.poloBlue22,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(
                color: KasyabaTokens.poloBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sheetPasswordInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: KasyabaTokens.periwinkleGraySubtitle,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: KasyabaTokens.periwinkleGray,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
              fontSize: 15,
              color: KasyabaTokens.poloBlue40,
            ),
            filled: true,
            fillColor: KasyabaTokens.bigStone,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 17,
            ),
            suffixIcon: GestureDetector(
              onTap: onToggleObscure,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 18, left: 10),
                child: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: KasyabaTokens.poloBlue,
                  size: 20,
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(
                color: KasyabaTokens.poloBlue22,
                width: 1.0,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: const BorderSide(
                color: KasyabaTokens.poloBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEditProfileSheet(String currentName) {
    AppHaptics.selectionClick();
    final nameController = TextEditingController(text: currentName);
    final isOnline = ref.read(isOnlineProvider);
    var isSubmitting = false;
    String? sheetError;

    showKasyabaSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

          return AppSheet(
            color: KasyabaTokens.ebony,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit Profile',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: KasyabaTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Update your display name as it appears in Kasyaba.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: KasyabaTokens.periwinkleGraySubtitle,
                  ),
                ),
                const SizedBox(height: 16),
                if (sheetError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: KasyabaTokens.apricot15,
                      border: Border.all(
                        color: KasyabaTokens.apricot.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: KasyabaTokens.apricot,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sheetError!,
                            style: GoogleFonts.dmSans(
                              color: KasyabaTokens.apricot,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _sheetTextInputField(
                  label: 'FULL NAME',
                  controller: nameController,
                  hint: 'e.g. Juan Dela Cruz',
                ),
                const SizedBox(height: 24),
                if (!isOnline) ...[
                  const NeedsInternetNotice(
                    message:
                        'Updating your profile needs an internet connection.',
                  ),
                  const SizedBox(height: 12),
                ],
                PillButton(
                  label: isSubmitting ? 'Saving...' : 'Save Changes',
                  onPressed: (isSubmitting || !isOnline)
                      ? null
                      : () async {
                          final trimmed = nameController.text.trim();
                          if (trimmed.isEmpty) {
                            setModalState(
                              () => sheetError = 'Name cannot be empty.',
                            );
                            return;
                          }
                          setModalState(() {
                            isSubmitting = true;
                            sheetError = null;
                          });
                          try {
                            await ref
                                .read(transactionMutatorProvider)
                                .updateProfile(displayName: trimmed);
                            ref
                                .read(authProvider.notifier)
                                .setDisplayName(trimmed);
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                            if (mounted) {
                              KasyabaToast.showSuccess(
                                context,
                                'Profile updated successfully.',
                              );
                            }
                          } catch (error) {
                            if (sheetContext.mounted) {
                              setModalState(
                                () => sheetError = friendlyErrorMessage(
                                  error,
                                  fallback: 'Could not update profile.',
                                ),
                              );
                            }
                          } finally {
                            if (sheetContext.mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showChangePasswordSheet() {
    AppHaptics.selectionClick();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    var isSubmitting = false;
    var obscureCurrent = true;
    var obscureNew = true;
    var obscureConfirm = true;
    String? sheetError;

    showKasyabaSheet<void>(
      context: context,
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

          return AppSheet(
            color: KasyabaTokens.ebony,
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Change Password',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: KasyabaTokens.periwinkleGray,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a strong password with at least 8 characters.',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: KasyabaTokens.periwinkleGraySubtitle,
                  ),
                ),
                const SizedBox(height: 16),
                if (sheetError != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: KasyabaTokens.apricot15,
                      border: Border.all(
                        color: KasyabaTokens.apricot.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: KasyabaTokens.apricot,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sheetError!,
                            style: GoogleFonts.dmSans(
                              color: KasyabaTokens.apricot,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                _sheetPasswordInputField(
                  label: 'CURRENT PASSWORD',
                  controller: currentPasswordController,
                  hint: 'Enter your current password',
                  obscure: obscureCurrent,
                  onToggleObscure: () =>
                      setModalState(() => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 14),
                _sheetPasswordInputField(
                  label: 'NEW PASSWORD',
                  controller: newPasswordController,
                  hint: 'At least 8 characters',
                  obscure: obscureNew,
                  onToggleObscure: () =>
                      setModalState(() => obscureNew = !obscureNew),
                ),
                const SizedBox(height: 14),
                _sheetPasswordInputField(
                  label: 'CONFIRM NEW PASSWORD',
                  controller: confirmPasswordController,
                  hint: 'Re-enter your new password',
                  obscure: obscureConfirm,
                  onToggleObscure: () =>
                      setModalState(() => obscureConfirm = !obscureConfirm),
                ),
                const SizedBox(height: 24),
                PillButton(
                  label: isSubmitting ? 'Updating...' : 'Update Password',
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final currentPass = currentPasswordController.text;
                          final newPass = newPasswordController.text;
                          final confirmPass = confirmPasswordController.text;

                          if (currentPass.isEmpty) {
                            setModalState(
                              () => sheetError =
                                  'Please enter your current password.',
                            );
                            return;
                          }
                          if (newPass.length < 8) {
                            setModalState(
                              () => sheetError =
                                  'New password must be at least 8 characters.',
                            );
                            return;
                          }
                          if (newPass != confirmPass) {
                            setModalState(
                              () => sheetError =
                                  'New passwords do not match.',
                            );
                            return;
                          }
                          if (currentPass == newPass) {
                            setModalState(
                              () => sheetError =
                                  'New password must be different from your current password.',
                            );
                            return;
                          }

                          setModalState(() {
                            isSubmitting = true;
                            sheetError = null;
                          });
                          try {
                            await ref
                                .read(authProvider.notifier)
                                .changePassword(
                                  currentPassword: currentPass,
                                  newPassword: newPass,
                                );
                            if (sheetContext.mounted) {
                              Navigator.of(sheetContext).pop();
                            }
                            if (mounted) {
                              KasyabaToast.showSuccess(
                                context,
                                'Password updated successfully.',
                              );
                            }
                          } catch (error) {
                            if (sheetContext.mounted) {
                              setModalState(
                                () => sheetError = friendlyErrorMessage(
                                  error,
                                  fallback: 'Failed to update password.',
                                ),
                              );
                            }
                          } finally {
                            if (sheetContext.mounted) {
                              setModalState(() => isSubmitting = false);
                            }
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KasyabaTokens.periwinkleGraySubtitle,
            ),
          ),
        ),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 21),
          decoration: BoxDecoration(
            color: KasyabaTokens.bigStone,
            borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
            border: Border.all(color: KasyabaTokens.poloBlue22, width: 1),
          ),
          child: Row(
            children: [
              Text(
                '₱ ',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: KasyabaTokens.periwinkleGray,
                ),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onChanged,
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: KasyabaTokens.periwinkleGray,
                  ),
                  cursorColor: KasyabaTokens.periwinkleGray,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: KasyabaTokens.poloBlue40,
                    ),
                    filled: false,
                    fillColor: Colors.transparent,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, double amount) {
    final isDeduction = amount < 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: KasyabaTokens.periwinkleGraySubtitle,
            ),
          ),
          Text(
            '${isDeduction ? '-' : ''}${CurrencyFormatter.format(amount.abs())}',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDeduction ? KasyabaTokens.apricot : KasyabaTokens.periwinkleGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KasyabaTokens.periwinkleGraySubtitle,
            ),
          ),
        ),
        Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 21),
          decoration: BoxDecoration(
            color: KasyabaTokens.bigStone,
            borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
            border: Border.all(color: KasyabaTokens.poloBlue22, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              borderRadius: BorderRadius.circular(20),
              dropdownColor: KasyabaTokens.bigStone,
              elevation: 12,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: KasyabaTokens.periwinkleGray,
                size: 24,
              ),
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: KasyabaTokens.periwinkleGray,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }



  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final budgetStatusAsync = ref.watch(budgetStatusProvider);

    final displayName = authState.displayName ?? 'User';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Profile',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: KasyabaTokens.periwinkleGray,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideEntrance.staggered(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: KasyabaTokens.cello60,
                    borderRadius: BorderRadius.circular(
                      KasyabaTokens.radiusCard,
                    ),
                    border: Border.all(
                      color: KasyabaTokens.poloBlue30,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: KasyabaTokens.periwinkleGray,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: KasyabaTokens.ebony,
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
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: KasyabaTokens.periwinkleGray,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              authState.email ?? 'No email set',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: KasyabaTokens.periwinkleGraySubtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'Edit profile name',
                        child: SpringTouch(
                          onTap: () => _showEditProfileSheet(displayName),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: KasyabaTokens.bigStone,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: KasyabaTokens.poloBlue22,
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: KasyabaTokens.bermuda,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 2,
                child: profileAsync.when(
                  loading: () => const KasyabaLoadingSkeleton(lines: 3),
                  error: (error, _) => KasyabaErrorCard(
                    message: friendlyErrorMessage(
                      error,
                      fallback: 'Could not load your salary settings.',
                    ),
                    onRetry: () => ref.invalidate(userProfileProvider),
                  ),
                  data: _buildSalaryCard,
                ),
              ),
              const SizedBox(height: 20),
              FadeSlideEntrance.staggered(
                index: 3,
                child: _sectionHeader('MONEY'),
              ),
              const SizedBox(height: 6),
              FadeSlideEntrance.staggered(
                index: 4,
                child: _settingsCard([
                  _SettingsRow(
                    title: 'Accounts and wallets',
                    subtitle: 'Cash, bank and e-wallets',
                    onTap: () => context.push('/accounts'),
                  ),
                  _divider(),
                  _SettingsRow(
                    title: 'Budgets',
                    subtitle: _budgetSubtitle(budgetStatusAsync),
                    onTap: () => context.push('/budgets'),
                  ),
                  _divider(),
                  _SettingsRow(
                    title: 'Notifications',
                    subtitle: 'Bill reminders and budget alerts',
                    onTap: () => context.push('/settings/notifications'),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              FadeSlideEntrance.staggered(
                index: 5,
                child: _sectionHeader('SECURITY'),
              ),
              const SizedBox(height: 6),
              FadeSlideEntrance.staggered(
                index: 6,
                child: _settingsCard([
                  _SettingsRow(
                    title: 'Change password',
                    subtitle: 'Update your account login password',
                    onTap: _showChangePasswordSheet,
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              FadeSlideEntrance.staggered(
                index: 7,
                child: _sectionHeader('YOUR DATA'),
              ),
              const SizedBox(height: 6),
              FadeSlideEntrance.staggered(
                index: 8,
                child: _settingsCard([
                  _SettingsRow(
                    title: 'Backup and export',
                    subtitle: 'JSON backup, restore, CSV for Excel',
                    onTap: () => context.push('/settings/backup'),
                  ),
                  _divider(),
                  _SettingsRow(
                    title: 'Privacy policy',
                    subtitle: 'Server-backed, cached on this device',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                  _divider(),
                  _SettingsRow(
                    title: 'About Kasyaba',
                    subtitle: 'Version $kAppVersionLabel',
                    onTap: () => context.push('/settings/privacy'),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              FadeSlideEntrance.staggered(
                index: 7,
                child: PillButton(
                  label: 'Sign out',
                  variant: PillButtonVariant.secondary,
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 8,
                child: Center(
                  child: SpringTouch(
                    onTap: () => context.push('/settings/delete-account'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      child: Text(
                        'Delete account and data',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: KasyabaTokens.apricot,
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

  Widget _buildSalaryCard(UserProfile profile) {
    final salary = profile.salaryAmount;
    final schedule = profile.paydaySchedule ?? '15th & 30th';

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: KasyabaTokens.bigStone,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
        border: Border.all(color: KasyabaTokens.poloBlue22, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Salary and payday',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: KasyabaTokens.periwinkleGray,
                ),
              ),
              if (salary != null)
                Tooltip(
                  message: 'Edit salary & payday settings',
                  child: SpringTouch(
                    onTap: () => _showSalarySheet(profile),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGraySubtitle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (salary == null) ...[
            Text(
              'No salary set',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: KasyabaTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add your net pay to unlock safe-to-spend, payday, and forecast calculations.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KasyabaTokens.periwinkleGraySubtitle,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            PillButton(
              label: 'Set salary',
              variant: PillButtonVariant.secondary,
              height: 48,
              onPressed: () => _showSalarySheet(profile),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${CurrencyFormatter.format(salary)} ',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: KasyabaTokens.periwinkleGray,
                  ),
                ),
                Text(
                  'per month',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: KasyabaTokens.periwinkleGraySubtitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Paid on the $schedule · ${CurrencyFormatter.format(_perPaycheck(salary, profile.paydayFrequency))} each',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: KasyabaTokens.periwinkleGraySubtitle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: KasyabaTokens.periwinkleGraySubtitle,
        ),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
      decoration: BoxDecoration(
        color: KasyabaTokens.bigStone,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
        border: Border.all(color: KasyabaTokens.poloBlue22, width: 1),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: KasyabaTokens.poloBlue16);
  }
}

class _SettingsRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SpringTouch(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: KasyabaTokens.periwinkleGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: KasyabaTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: KasyabaTokens.periwinkleGraySubtitle,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
