import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
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
      {'name': 'Emergency Fund', 'icon': '🛡️'},
      {'name': 'Tuition Fee', 'icon': '🎓'},
      {'name': 'New Gadget', 'icon': '📱'},
      {'name': 'Vacation Trip', 'icon': '✈️'},
      {'name': 'Vehicle', 'icon': '🚗'},
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
                      avatar: Text(preset['icon']!),
                      label: Text(preset['name']!),
                      onPressed: () {
                        _goalNameController.text = preset['name']!;
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
                      borderRadius: BorderRadius.zero,
                      border: Border.all(
                        color: targetDate != null
                            ? AppColors.emerald500
                            : const Color(0xFF1F293D),
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
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
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
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                    color: Color(0xFF1F293D),
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
                            size: 16,
                            color: AppColors.emerald500,
                          ),
                          label: Text('₱${amt.toString()}'),
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
                                        'Added ₱${amount.toStringAsFixed(2)} to ${goal.name}! 🎉',
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
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
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

    PurchaseCheckResult? checkResult;
    String? errorMessage;
    bool isLoading = false;

    ModernBottomSheet.show(
      context: context,
      title: 'Can I Buy This? 🛍️📱',
      subtitle:
          'Deterministic financial impact calculation on cash flow, bills, and threshold.',
      child: StatefulBuilder(
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
                  hint: 'e.g. Smartphone, New Headphones, Concert Ticket',
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
                          final title = _purchaseTitleController.text.trim();
                          final amount =
                              double.tryParse(
                                _purchaseAmountController.text.trim(),
                              ) ??
                              0.0;

                          try {
                            final mutator = ref.read(
                              transactionMutatorProvider,
                            );
                            final result = await mutator.evaluatePurchaseCheck(
                              itemTitle: title,
                              amount: amount,
                            );
                            if (context.mounted) {
                              setModalState(() {
                                checkResult = result;
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
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero,
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
                  _PurchaseCheckCardResult(result: checkResult!),
                ],
                const SizedBox(height: 12),
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
        actions: [
          Tooltip(
            message: 'Can I Buy This? (Purchase Check)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showPurchaseCheckBottomSheet(context),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 19,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Create Savings Goal',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showAddGoalBottomSheet(context),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.zero,
                        color: AppColors.emerald500.withValues(alpha: 0.15),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 20,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.emerald500,
        onRefresh: () async => ref.invalidate(goalsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
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
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
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
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
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
      borderRadius: 0.0,
      backgroundColor: AppColors.surfaceCard,
      borderColor: const Color(0xFF1F293D),
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
                  borderRadius: BorderRadius.zero,
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
                      'Target: ₱${goal.targetAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                children: [
                  InkWell(
                    onTap: onDeposit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.zero,
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
                      borderRadius: BorderRadius.zero,
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
                    '₱${goal.currentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald500,
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
                    '₱${remaining.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
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
                decoration: const BoxDecoration(
                  color: Color(0xFF161E2E),
                  borderRadius: BorderRadius.zero,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 8,
                    width: filledWidth,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF047857), Color(0xFF10B981)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.zero,
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

  const _PurchaseCheckCardResult({required this.result});

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: cardColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cardColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.statusTitle,
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
            ),
          ),
          const Divider(height: 24),

          for (final reason in result.reasons) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cardColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        color: AppColors.textDark,
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
          borderRadius: BorderRadius.zero,
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
                'Goal Completed! 🎉 You can fully afford this goal.',
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
          ? 'Requires ~₱${reqMonthly.toStringAsFixed(0)}/month in net savings.'
          : 'Your current daily cash flow covers this goal on schedule.';
    } else if (canAfford == false) {
      bannerColor = AppColors.gold500;
      icon = Icons.warning_amber_rounded;
      statusTitle = 'Target date unlikely at current savings rate';
      statusDetail = earliestDate != null
          ? 'Estimated afford date: ${_formatDateStr(earliestDate)} (Needs ~₱${reqMonthly?.toStringAsFixed(0)}/mo to hit target date).'
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
        borderRadius: BorderRadius.zero,
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
