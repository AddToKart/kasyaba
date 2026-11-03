import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/theme/app_motion.dart';
import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/app_info.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/ph_salary_calculator.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_toast.dart';
import '../../../shared/widgets/motion_components.dart';
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
  final _minThresholdController = TextEditingController();

  @override
  void dispose() {
    _salaryController.dispose();
    _grossSalaryController.dispose();
    _allowancesController.dispose();
    _minThresholdController.dispose();
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
              child: SingleChildScrollView(
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
                                          color: KasyabaTokens.bigStone,
                                          borderRadius: BorderRadius.circular(
                                            KasyabaTokens.radiusCard,
                                          ),
                                          border: Border.all(
                                            color: KasyabaTokens.poloBlue22,
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
                      context: sheetContext,
                      label: 'Payout Frequency',
                      value: paydayFreq,
                      options: const [
                        (
                          value: 'semi-monthly',
                          title: 'Semi-monthly (Twice a month)',
                          subtitle: 'Standard PH schedule: 15th & 30th payouts',
                        ),
                        (
                          value: 'monthly',
                          title: 'Monthly (Once a month)',
                          subtitle: 'Paid once per calendar month',
                        ),
                        (
                          value: 'weekly',
                          title: 'Weekly (Every 7 days)',
                          subtitle: 'Paid once every week',
                        ),
                        (
                          value: 'bi-weekly',
                          title: 'Bi-weekly (Every 14 days)',
                          subtitle: 'Paid every two weeks (26 paydays/year)',
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => paydayFreq = value);
                      },
                    ),
                    const SizedBox(height: 14),
                    _sheetDropdown(
                      context: sheetContext,
                      label: 'Payout Schedule',
                      value: paydaySched,
                      options: const [
                        (
                          value: '15th & 30th',
                          title: '15th & 30th (Standard PH)',
                          subtitle: 'Standard mid-month and month-end paydays',
                        ),
                        (
                          value: '10th & 25th',
                          title: '10th & 25th',
                          subtitle: 'Common alternative semi-monthly cycle',
                        ),
                        (
                          value: 'End of Month',
                          title: 'End of Month (Last working day)',
                          subtitle: 'Single monthly payout at month end',
                        ),
                        (
                          value: 'Custom / Other',
                          title: 'Custom / Other',
                          subtitle: 'Customized schedule or irregular paydays',
                        ),
                      ],
                      onChanged: (value) {
                        setModalState(() => paydaySched = value);
                      },
                    ),
                    const SizedBox(height: 20),
                    PillButton(
                      label: 'Save settings',
                      isLoading: isSubmitting,
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              double? finalSalary;
                              if (isCalculatorMode && liveBreakdown != null) {
                                finalSalary = liveBreakdown!.netMonthlyPay;
                              } else {
                                finalSalary = double.tryParse(
                                  _salaryController.text.trim(),
                                );
                              }

                              final threshold =
                                  double.tryParse(
                                    _minThresholdController.text.trim(),
                                  ) ??
                                  0.0;

                              setModalState(() => isSubmitting = true);
                              try {
                                await ref
                                    .read(transactionMutatorProvider)
                                    .updateProfile(
                                      salaryAmount: finalSalary,
                                      paydayFrequency: paydayFreq,
                                      paydaySchedule: paydaySched,
                                      minimumBalanceThreshold: threshold,
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
    required BuildContext context,
    required String label,
    required String value,
    required List<({String value, String title, String subtitle})> options,
    required ValueChanged<String> onChanged,
  }) {
    final selectedOption = options.firstWhere(
      (opt) => opt.value == value,
      orElse: () => options.first,
    );

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
        SpringTouch(
          onTap: () {
            AppHaptics.selectionClick();
            _showOptionPickerSheet(
              context: context,
              title: label,
              currentValue: value,
              options: options,
              onSelected: onChanged,
            );
          },
          child: Container(
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 21),
            decoration: BoxDecoration(
              color: KasyabaTokens.bigStone,
              borderRadius: BorderRadius.circular(KasyabaTokens.radiusCard),
              border: Border.all(color: KasyabaTokens.poloBlue22, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedOption.title,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: KasyabaTokens.periwinkleGray,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: KasyabaTokens.periwinkleGray,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showOptionPickerSheet({
    required BuildContext context,
    required String title,
    required String currentValue,
    required List<({String value, String title, String subtitle})> options,
    required ValueChanged<String> onSelected,
  }) async {
    await showKasyabaSheet<void>(
      context: context,
      builder: (ctx) => AppSheet(
        color: KasyabaTokens.ebony,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: KasyabaTokens.periwinkleGray,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Select an option from the list below',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: KasyabaTokens.periwinkleGraySubtitle,
              ),
            ),
            const SizedBox(height: 18),
            ...options.map((opt) {
              final isSelected = opt.value == currentValue;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SpringTouch(
                  onTap: () {
                    AppHaptics.selectionClick();
                    onSelected(opt.value);
                    Navigator.of(ctx).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? KasyabaTokens.cello60 : KasyabaTokens.bigStone,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? KasyabaTokens.poloBlue30 : KasyabaTokens.poloBlue22,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt.title,
                                style: GoogleFonts.dmSans(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  color: KasyabaTokens.periwinkleGray,
                                ),
                              ),
                              if (opt.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  opt.subtitle,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: KasyabaTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: KasyabaTokens.casablanca,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
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
                child: _sectionHeader('YOUR DATA'),
              ),
              const SizedBox(height: 6),
              FadeSlideEntrance.staggered(
                index: 6,
                child: _settingsCard([
                  _SettingsRow(
                    title: 'Backup and export',
                    subtitle: 'JSON backup, restore, CSV for Excel',
                    onTap: () => context.push('/settings/backup'),
                  ),
                  _divider(),
                  _SettingsRow(
                    title: 'Privacy policy',
                    subtitle: 'Your data stays on your device',
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
