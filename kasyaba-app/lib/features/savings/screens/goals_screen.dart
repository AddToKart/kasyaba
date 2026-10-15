import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/router/app_shell.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/modern_card.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/modern_bottom_sheet.dart';
import '../../../shared/widgets/modern_text_field.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  final _goalNameController = TextEditingController();
  final _goalAmountController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _purchaseTitleController = TextEditingController();
  final _purchaseAmountController = TextEditingController();

  @override
  void dispose() {
    _goalNameController.dispose();
    _goalAmountController.dispose();
    _depositAmountController.dispose();
    _purchaseTitleController.dispose();
    _purchaseAmountController.dispose();
    super.dispose();
  }

  void _showAddGoalBottomSheet(BuildContext context) {
    _goalNameController.clear();
    _goalAmountController.clear();
    final formKey = GlobalKey<FormState>();
    DateTime? targetDate;
    var isSubmitting = false;

    final presets = [
      {'name': 'Emergency Fund', 'icon': Icons.shield_outlined},
      {'name': 'Tuition Fee', 'icon': Icons.school_outlined},
      {'name': 'New Gadget', 'icon': Icons.devices_outlined},
      {'name': 'Vacation Trip', 'icon': Icons.flight_outlined},
      {'name': 'Vehicle', 'icon': Icons.directions_car_outlined},
    ];

    ModernBottomSheet.show(
      context: context,
      title: 'Create Savings Goal',
      subtitle:
          'Set a target amount and optional date for affordability forecasting.',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Presets',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: presets.map((preset) {
                    return ActionChip(
                      avatar: Icon(
                        preset['icon'] as IconData,
                        size: 15,
                        color: AppColors.emerald500,
                      ),
                      label: Text(preset['name'] as String),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.tagRadius),
                        side: const BorderSide(color: AppColors.subtleBorder),
                      ),
                      onPressed: () {
                        _goalNameController.text = preset['name'] as String;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                ModernTextField(
                  controller: _goalNameController,
                  label: 'Goal Name',
                  hint: 'e.g. Emergency Fund, New Laptop',
                  prefixIcon: Icons.flag_outlined,
                  validator: (v) => (v?.trim().length ?? 0) > 0
                      ? null
                      : 'Goal name is required',
                ),
                const SizedBox(height: 16),

                ModernTextField(
                  controller: _goalAmountController,
                  label: 'Target Amount (₱)',
                  hint: '50000.00',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter target amount';
                    }
                    final amount = double.tryParse(v);
                    if (amount == null || !amount.isFinite || amount <= 0) {
                      return 'Enter an amount greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Target Date Picker Button
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 90)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null && context.mounted) {
                      setModalState(() {
                        targetDate = picked;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface700,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: targetDate != null
                            ? AppColors.emerald500
                            : AppColors.subtleBorder,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          size: 20,
                          color: AppColors.emerald500,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target Completion Date (Optional)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                targetDate != null
                                    ? DateFormat(
                                        'MMMM d, yyyy',
                                      ).format(targetDate!)
                                    : 'Select date for goal forecast',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: targetDate != null
                                      ? AppColors.emerald500
                                      : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (targetDate != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              setModalState(() => targetDate = null);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                FilledButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isSubmitting = true);
                          final name = _goalNameController.text.trim();
                          final amount =
                              double.tryParse(
                                _goalAmountController.text.trim(),
                              ) ??
                              0.0;
                          final mutator = ref.read(transactionMutatorProvider);
                          try {
                            await mutator.addGoal(
                              name: name,
                              targetAmount: amount,
                              targetDate: targetDate,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    friendlyErrorMessage(
                                      error,
                                      fallback:
                                          'Unable to create this goal. Please try again.',
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
                    isSubmitting ? 'Creating Goal...' : 'Create Savings Goal',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  void _showAddDepositBottomSheet(BuildContext context, SavingsGoal goal) {
    _depositAmountController
      ..clear()
      ..text = '1000';
    final formKey = GlobalKey<FormState>();
    final presetAmounts = [500, 1000, 2500, 5000];

    var isSubmitting = false;
    String? selectedAccountId;

    ModernBottomSheet.show(
      context: context,
      title: 'Add Savings Deposit',
      subtitle: 'Contribute funds towards "${goal.name}".',
      child: Consumer(
        builder: (context, ref, child) {
          final accountsAsync = ref.watch(accountsProvider);
          final accounts = accountsAsync.valueOrNull ?? const <Account>[];
          if (accounts.isNotEmpty) {
            selectedAccountId ??= accounts.first.id;
          }

          return StatefulBuilder(
            builder: (context, setModalState) {
              // Deposits require an account whenever the user has accounts;
              // while the list is still loading we cannot pick one yet.
              final accountReady = accounts.isEmpty
                  ? !accountsAsync.isLoading
                  : selectedAccountId != null;
              final canSubmit = accountReady && !isSubmitting;

              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    accountsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                      data: (accounts) {
                        if (accounts.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deduct From Account',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedAccountId,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: AppColors.emerald500,
                                ),
                                filled: true,
                                fillColor: AppColors.surface700,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.subtleBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                  borderSide: BorderSide(
                                    color: AppColors.subtleBorder,
                                  ),
                                ),
                              ),
                              items: accounts.map((acc) {
                                return DropdownMenuItem<String>(
                                  value: acc.id,
                                  child: Text(
                                    acc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() => selectedAccountId = val);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        );
                      },
                    ),

                    const Text(
                      'Quick Deposit Amounts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetAmounts.map((amt) {
                        return ActionChip(
                          avatar: const Icon(
                            Icons.add_rounded,
                            size: 15,
                            color: AppColors.emerald500,
                          ),
                          label: Text(CurrencyFormatter.formatInteger(amt)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.tagRadius,
                            ),
                            side: const BorderSide(
                              color: AppColors.subtleBorder,
                            ),
                          ),
                          onPressed: () {
                            _depositAmountController.text = amt.toString();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    ModernTextField(
                      controller: _depositAmountController,
                      label: 'Deposit Amount (₱)',
                      hint: '1000.00',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter deposit amount';
                        }
                        final amount = double.tryParse(v);
                        if (amount == null || !amount.isFinite || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: canSubmit
                          ? () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => isSubmitting = true);
                              final amount =
                                  double.tryParse(
                                    _depositAmountController.text.trim(),
                                  ) ??
                                  0.0;
                              final mutator = ref.read(
                                transactionMutatorProvider,
                              );
                              try {
                                await mutator.addGoalContribution(
                                  goalId: goal.id,
                                  amount: amount,
                                  accountId: selectedAccountId,
                                  notes: 'Savings deposit',
                                );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added ${CurrencyFormatter.format(amount)} to ${goal.name}.',
                                      ),
                                      backgroundColor: AppColors.emerald500,
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
                                              'Unable to add this deposit. Please try again.',
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
                            }
                          : null,
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add_circle_outline, size: 20),
                      label: Text(
                        isSubmitting
                            ? 'Adding Deposit...'
                            : 'Add Savings Deposit',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald500,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showPurchaseCheckBottomSheet(BuildContext context) {
    _purchaseTitleController.clear();
    _purchaseAmountController.clear();
    final formKey = GlobalKey<FormState>();
    final interestRateController = TextEditingController(text: '0.0');

    bool isInstallment = false;
    int tenureMonths = 3;
    PurchaseCheckResult? checkResult;
    double evaluatedAmount = 0.0;
    bool evaluatedIsInstallment = false;
    int evaluatedTenure = 3;
    double evaluatedInterestRate = 0.0;
    String? errorMessage;
    bool isLoading = false;

    ModernBottomSheet.show(
      context: context,
      title: 'Can I Buy This? Scenario Lab',
      subtitle:
          'Deterministic calculation of life-energy work hours, cash flow, and installment impact.',
      showDragHandle: false,
      child: Consumer(
        builder: (context, ref, _) {
          final userProfile = ref.watch(userProfileProvider).valueOrNull;
          final dashboardData = ref.watch(dashboardProvider).valueOrNull;
          final bills = ref.watch(billsProvider).valueOrNull ?? const [];
          final goals = ref.watch(goalsProvider).valueOrNull ?? const [];

          final safeSpendCalc = calculateDailySafeSpend(
            totalLiquidBalance:
                (dashboardData?.totalBalance ?? 0.0).toDouble(),
            bills: bills,
            goals: goals,
            profile: userProfile,
          );

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModernTextField(
                      controller: _purchaseTitleController,
                      label: 'Item / Purchase Name',
                      hint: 'e.g. Smartphone, Laptop, Concert Ticket',
                      prefixIcon: Icons.shopping_bag_outlined,
                      validator: (v) => (v?.trim().length ?? 0) > 0
                          ? null
                          : 'Item name is required',
                    ),
                    const SizedBox(height: 14),

                    ModernTextField(
                      controller: _purchaseAmountController,
                      label: 'Item Price (₱)',
                      hint: '5000.00',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter item price';
                        }
                        final amount = double.tryParse(v);
                        if (amount == null || !amount.isFinite || amount <= 0) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── Cash vs. Installment Mode Toggle ──────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface800,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.subtleBorder),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Row(
                        children: [
                          Expanded(
                            child: _PaymentModeToggleBtn(
                              label: 'Pay Full Cash',
                              icon: Icons.payments_outlined,
                              isSelected: !isInstallment,
                              onTap: () =>
                                  setModalState(() => isInstallment = false),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: _PaymentModeToggleBtn(
                              label: 'Installment / BNPL',
                              icon: Icons.splitscreen_rounded,
                              isSelected: isInstallment,
                              onTap: () =>
                                  setModalState(() => isInstallment = true),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Installment Tenure & Monthly Interest % Input ─────
                    if (isInstallment) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface800,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Installment Tenure Duration',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [3, 6, 12].map((months) {
                                final isSelected = tenureMonths == months;
                                return Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 3),
                                    child: InkWell(
                                      onTap: () => setModalState(
                                        () => tenureMonths = months,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColors.info
                                                  .withValues(alpha: 0.2)
                                              : AppColors.surface700,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.info
                                                : AppColors.subtleBorder,
                                            width: isSelected ? 1.5 : 1,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$months Months',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isSelected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.info
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            ModernTextField(
                              controller: interestRateController,
                              label: 'Monthly Interest Rate (%)',
                              hint: '0.0 (0% for interest-free promos)',
                              prefixIcon: Icons.percent_rounded,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                final rate = double.tryParse(v.trim());
                                if (rate == null ||
                                    !rate.isFinite ||
                                    rate < 0) {
                                  return 'Enter a valid rate (e.g. 0.0 or 2.5)';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    FilledButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() {
                                isLoading = true;
                                errorMessage = null;
                              });
                              final title =
                                  _purchaseTitleController.text.trim();
                              final amount = double.tryParse(
                                    _purchaseAmountController.text.trim(),
                                  ) ??
                                  0.0;
                              final interestRate = double.tryParse(
                                    interestRateController.text.trim(),
                                  ) ??
                                  0.0;

                              try {
                                final mutator = ref.read(
                                  transactionMutatorProvider,
                                );
                                final evalAmount = isInstallment
                                    ? ((amount *
                                            (1 +
                                                (interestRate / 100.0) *
                                                    tenureMonths)) /
                                        tenureMonths)
                                    : amount;
                                final evalTitle = isInstallment
                                    ? '$title (${tenureMonths}m Installment: ₱${evalAmount.toStringAsFixed(2)}/mo)'
                                    : title;

                                final result =
                                    await mutator.evaluatePurchaseCheck(
                                  itemTitle: evalTitle,
                                  amount: evalAmount,
                                );
                                if (context.mounted) {
                                  setModalState(() {
                                    checkResult = result;
                                    evaluatedAmount = amount;
                                    evaluatedIsInstallment = isInstallment;
                                    evaluatedTenure = tenureMonths;
                                    evaluatedInterestRate = interestRate;
                                    isLoading = false;
                                  });
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  setModalState(() {
                                    errorMessage = friendlyErrorMessage(
                                      error,
                                      fallback:
                                          'Could not evaluate this purchase. Please try again.',
                                    );
                                    isLoading = false;
                                  });
                                }
                              }
                            },
                      icon: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.analytics_outlined, size: 20),
                      label: Text(
                        isLoading
                            ? 'Calculating Impact...'
                            : 'Evaluate Affordability',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0284C7),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.expense,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    if (checkResult != null) ...[
                      const SizedBox(height: 20),
                      _PurchaseCheckCardResult(
                        result: checkResult!,
                        purchaseAmount: evaluatedAmount,
                        isInstallment: evaluatedIsInstallment,
                        tenureMonths: evaluatedTenure,
                        monthlyInterestRate: evaluatedInterestRate,
                        userProfile: userProfile,
                        daysUntilPayday: safeSpendCalc.daysUntilPayday,
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Savings Goals',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.emerald500,
        onRefresh: () async => ref.invalidate(goalsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            _CanIBuyThisHeroCard(
              isDark: isDark,
              onTap: () => _showPurchaseCheckBottomSheet(context),
            ),
            const SizedBox(height: 18),
            goalsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.emerald500),
                ),
              ),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.expense,
                      size: 30,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      friendlyErrorMessage(
                        err,
                        fallback: 'Could not load your savings goals.',
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.tonal(
                      onPressed: () => ref.invalidate(goalsProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (goals) {
                if (goals.isEmpty) {
                  return ModernCard(
                    padding: EdgeInsets.zero,
                    child: EmptyStateView(
                      title: 'No Savings Goals Yet',
                      message:
                          'Set target savings goals for your Emergency Fund, Tuition Fee, or a New Gadget.',
                      icon: Icons.track_changes_outlined,
                      actionLabel: 'Create Goal',
                      onAction: () => _showAddGoalBottomSheet(context),
                    ),
                  );
                }

                return Column(
                  children: [
                    for (final goal in goals) ...[
                      _ModernGoalCard(
                        goal: goal,
                        isDark: isDark,
                        onDeposit: () =>
                            _showAddDepositBottomSheet(context, goal),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingDockFabLocation(
        bottomPadding: MediaQuery.viewPaddingOf(context).bottom,
        gap: 20.0,
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.emerald500,
          border: Border.all(
            color: AppColors.gold500.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddGoalBottomSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded, size: 22, color: Colors.black),
          label: const Text(
            'New Goal',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.black,
              letterSpacing: 0.5,
            ),
          ),
          tooltip: 'Create Goal',
        ),
      ),
    );
  }
}

// ─── "Can I Buy This?" Affordability Simulator Feature Card ──────────────────

class _CanIBuyThisHeroCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onTap;

  const _CanIBuyThisHeroCard({
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface800 : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 20,
                          color: Color(0xFF38BDF8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Can I Buy This?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: isDark
                                      ? AppColors.textDark
                                      : AppColors.textLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7)
                                      .withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.tagRadius,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8)
                                        .withValues(alpha: 0.45),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'SIMULATOR',
                                  style: TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simulate any purchase before you spend. Evaluates bill conflicts, cash buffer, and savings goal delays.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textMutedL,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? const Color(0xFF0B132B)
                            : const Color(0xFFF0F9FF))
                        .withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFF38BDF8),
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Test purchase impact on goals',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF38BDF8),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF38BDF8)
                                .withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Simulate',
                              style: TextStyle(
                                color: Color(0xFF38BDF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 12,
                              color: Color(0xFF38BDF8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Modern Redesigned Savings Goal Card (Sharp Rectilinear Geometry) ────────

class _ModernGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;
  final VoidCallback onDeposit;

  const _ModernGoalCard({
    required this.goal,
    required this.isDark,
    required this.onDeposit,
  });

  @override
  Widget build(BuildContext context) {
    final progressPct = (goal.progress * 100)
        .clamp(0.0, 100.0)
        .toStringAsFixed(0);
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );

    return ModernCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20.0,
      backgroundColor: AppColors.surfaceCard,
      borderColor: AppColors.subtleBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF047857), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.emerald400.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ${CurrencyFormatter.format(goal.targetAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  InkWell(
                    onTap: onDeposit,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: AppColors.emerald500,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Deposit',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.emerald500,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9999),
                      border: Border.all(
                        color: AppColors.gold500.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '$progressPct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.gold400,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(goal.currentAmount),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald500,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(remaining),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final filledWidth = barWidth * goal.progress.clamp(0.0, 1.0);

              return Container(
                height: 8,
                width: barWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF161E2E),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: filledWidth,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF10B981)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
          _GoalForecastBanner(goal: goal, isDark: isDark),
        ],
      ),
    );
  }
}

class _PurchaseCheckCardResult extends StatelessWidget {
  final PurchaseCheckResult result;
  final double purchaseAmount;
  final bool isInstallment;
  final int tenureMonths;
  final double monthlyInterestRate;
  final UserProfile? userProfile;
  final int daysUntilPayday;

  const _PurchaseCheckCardResult({
    required this.result,
    required this.purchaseAmount,
    required this.isInstallment,
    required this.tenureMonths,
    required this.monthlyInterestRate,
    this.userProfile,
    this.daysUntilPayday = 14,
  });

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    IconData icon;

    if (result.verdict == 'AFFORDABLE') {
      cardColor = AppColors.emerald500;
      icon = Icons.check_circle_rounded;
    } else if (result.verdict == 'RISKY') {
      cardColor = AppColors.gold500;
      icon = Icons.warning_rounded;
    } else {
      cardColor = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
    }

    // Strip any leading emoji from statusTitle to ensure no duplicate icons
    final cleanTitle = result.statusTitle
        .replaceAll(RegExp(r'^[^\w\s]+\s*'), '')
        .trim();

    final workHours = calculateWorkHoursEquivalent(
      itemPrice: purchaseAmount,
      monthlySalary: userProfile?.salaryAmount,
    );

    final comp = calculateInstallmentComparison(
      purchaseAmount: purchaseAmount,
      tenureMonths: tenureMonths,
      monthlyInterestRatePercent: monthlyInterestRate,
      currentBalance: result.currentBalance,
      daysUntilPayday: daysUntilPayday,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.35), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: cardColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cleanTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            result.statusMessage,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),

          // ── Work-Hours Equivalent Life-Energy Metric Badge ───────────
          if (workHours.hasSalary)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.hourglass_top_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textDark,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Time Cost: ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              TextSpan(
                                text:
                                    '${workHours.workHours.toStringAsFixed(1)} Work Hours (${workHours.workDays.toStringAsFixed(1)} Workdays)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Based on ₱${CurrencyFormatter.format(workHours.salaryAmount!)}/mo salary (₱${workHours.hourlyWage.toStringAsFixed(2)}/hr across 176 monthly work hours)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold500.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.gold500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.schedule_outlined,
                      color: AppColors.gold400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Time Cost: Salary Not Configured',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.gold400,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Configure Monthly Salary in Settings to see work-hours equivalent.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // ── Cash vs. Installment Comparator Card ───────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface800,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.splitscreen_rounded,
                          size: 15,
                          color: AppColors.gold400,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'CASH VS. INSTALLMENT COMPARATOR',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.gold400,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isInstallment
                                ? AppColors.info
                                : AppColors.emerald500)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isInstallment
                            ? 'Testing ${tenureMonths}m Installment'
                            : 'Testing Full Cash',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isInstallment
                              ? AppColors.info
                              : AppColors.emerald500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2-Column Comparator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Pay Full Cash
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: !isInstallment
                              ? AppColors.emerald500.withValues(alpha: 0.08)
                              : AppColors.surface700.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: !isInstallment
                                ? AppColors.emerald500.withValues(alpha: 0.35)
                                : AppColors.subtleBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PAY FULL CASH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.emerald400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Immediate Outlay',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(comp.purchaseAmount)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Liquid Balance Today',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              CurrencyFormatter.format(comp.postCashBalance),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: comp.postCashBalance < 0
                                    ? AppColors.expense
                                    : AppColors.textDark,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Daily Safe Impact',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(comp.cashDailySafeSpendImpact)}/day',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF87171),
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Future Cash Flow',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const Text(
                              '₱0/mo (Debt-free)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald400,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Total Interest',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const Text(
                              '₱0.00 (0%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Column 2: Installment / BNPL
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isInstallment
                              ? AppColors.info.withValues(alpha: 0.08)
                              : AppColors.surface700.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isInstallment
                                ? AppColors.info.withValues(alpha: 0.35)
                                : AppColors.subtleBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'INSTALLMENT (${comp.tenureMonths}M)',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1st Month Outlay',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(comp.monthlyInstallment)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Cash Preserved Today',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '+${CurrencyFormatter.format(comp.cashPreservedToday)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald400,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Daily Safe Impact',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(comp.installmentDailySafeSpendImpact)}/day',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.info,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Future Cash Flow',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              '-${CurrencyFormatter.format(comp.monthlyInstallment)}/mo',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold400,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Total Interest',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                              ),
                            ),
                            Text(
                              comp.totalInterest > 0
                                  ? '+${CurrencyFormatter.format(comp.totalInterest)} (${comp.monthlyInterestRatePercent}%/mo)'
                                  : '₱0.00 (0% Promo)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: comp.totalInterest > 0
                                    ? const Color(0xFFF87171)
                                    : AppColors.emerald400,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Comparator Insights
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        comp.totalInterest > 0
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        size: 14,
                        color: comp.totalInterest > 0
                            ? AppColors.gold400
                            : AppColors.emerald400,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          comp.totalInterest > 0
                              ? 'Installment preserves ${CurrencyFormatter.format(comp.cashPreservedToday)} in your account today, but incurs an extra ${CurrencyFormatter.format(comp.totalInterest)} in total interest fees over ${comp.tenureMonths} months.'
                              : '0% BNPL preserves ${CurrencyFormatter.format(comp.cashPreservedToday)} of immediate cash today with ₱0 interest fees, while deducting ${CurrencyFormatter.format(comp.monthlyInstallment)}/mo from your future cash flow for ${comp.tenureMonths} months.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 2-Column Before vs. After Simulation Card ──────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface800,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.subtleBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 15,
                      color: AppColors.gold400,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'BEFORE VS. AFTER SIMULATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.gold400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column 1: Current (Before)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface700.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.subtleBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BEFORE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Current Balance',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(result.currentBalance),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Month-End Forecast',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(
                                result.projectedMonthEndBalance,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Column 2: Post-Purchase (After)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: cardColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AFTER PURCHASE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: cardColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Post-Purchase Balance',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(
                                result.postPurchaseBalance,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: result.postPurchaseBalance < 0
                                    ? AppColors.expense
                                    : AppColors.textDark,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Adjusted Forecast',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(
                                result.postPurchaseMonthEndBalance,
                              ),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: cardColor,
                                fontFeatures: CurrencyFormatter.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (result.earliestSafeBuyDate != null &&
              result.daysUntilSafeBuy != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface700,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.subtleBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.gold400,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Safe to purchase on ${result.earliestSafeBuyDate} (${result.daysUntilSafeBuy} days remaining)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (result.reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.subtleBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'ANALYSIS DETAILS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.reasons.map(
                    (reason) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              reason,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (result.goalImpacts.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.gold500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        size: 14,
                        color: AppColors.gold400,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'SAVINGS GOAL IMPACT',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.gold400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...result.goalImpacts.map(
                    (impact) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: AppColors.gold400,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${impact.goalName}: delayed by ~${impact.delayDays} day${impact.delayDays == 1 ? '' : 's'}${impact.delayedTargetDate != null ? ' (new date: ${impact.delayedTargetDate})' : ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDark,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentModeToggleBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentModeToggleBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface700 : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppColors.subtleBorder, width: 1)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.emerald400 : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.textDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalForecastBanner extends StatelessWidget {
  final SavingsGoal goal;
  final bool isDark;

  const _GoalForecastBanner({required this.goal, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(
      0.0,
      double.infinity,
    );
    if (remaining <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.emerald500.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.emerald500.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.stars_rounded, size: 18, color: AppColors.emerald500),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Goal Completed! You can fully afford this goal.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.emerald500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final canAfford = goal.canAffordByTargetDate;
    final earliestDate = goal.earliestAffordableDate;
    final reqMonthly = goal.monthlySavingsRequired;

    Color bannerColor;
    IconData icon;
    String statusTitle;
    String statusDetail;

    if (canAfford == true) {
      bannerColor = AppColors.emerald500;
      icon = Icons.check_circle_outline_rounded;
      statusTitle = goal.targetDate != null
          ? 'On Track to afford by ${_formatDateStr(goal.targetDate)}'
          : 'Can afford by ${_formatDateStr(earliestDate)}';
      statusDetail = reqMonthly != null && reqMonthly > 0
          ? 'Requires ~${CurrencyFormatter.format(reqMonthly, decimalDigits: 0)}/month in net savings.'
          : 'Your current daily cash flow covers this goal on schedule.';
    } else if (canAfford == false) {
      bannerColor = AppColors.gold500;
      icon = Icons.warning_amber_rounded;
      statusTitle = 'Target date unlikely at current savings rate';
      statusDetail = earliestDate != null
          ? 'Estimated afford date: ${_formatDateStr(earliestDate)} (Needs ~${CurrencyFormatter.format(reqMonthly ?? 0, decimalDigits: 0)}/mo to hit target date).'
          : 'Increase savings contributions to reach target date.';
    } else {
      bannerColor = const Color(0xFF0284C7);
      icon = Icons.insights_rounded;
      statusTitle = earliestDate != null
          ? 'Estimated afford date: ${_formatDateStr(earliestDate)}'
          : 'Calculating affordability timeline...';
      statusDetail = 'Based on your net daily income & expense cash flow.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: bannerColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: bannerColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusDetail,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateStr(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(parsed);
    } catch (_) {
      return dateStr;
    }
  }
}
