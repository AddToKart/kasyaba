import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
  void _showAddGoalBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? targetDate;

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
      subtitle: 'Set a target amount and optional date for affordability forecasting.',
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                        nameController.text = preset['name']!;
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                ModernTextField(
                  controller: nameController,
                  label: 'Goal Name',
                  hint: 'e.g. Emergency Fund, New Laptop',
                  prefixIcon: Icons.flag_outlined,
                  validator: (v) => (v?.trim().length ?? 0) > 0 ? null : 'Goal name is required',
                ),
                const SizedBox(height: 16),

                ModernTextField(
                  controller: amountController,
                  label: 'Target Amount (₱)',
                  hint: '50000.00',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter target amount';
                    if (double.tryParse(v) == null) return 'Enter a valid number';
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
                    if (picked != null) {
                      setModalState(() {
                        targetDate = picked;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: targetDate != null ? const Color(0xFF10B981) : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20, color: Color(0xFF10B981)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Target Completion Date (Optional)',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                targetDate != null
                                    ? DateFormat('MMMM d, yyyy').format(targetDate!)
                                    : 'Select date for goal forecast',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: targetDate != null ? const Color(0xFF10B981) : null,
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    final mutator = ref.read(transactionMutatorProvider);
                    await mutator.addGoal(
                      name: name,
                      targetAmount: amount,
                      targetDate: targetDate,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Create Savings Goal', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
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

  void _showAddDepositBottomSheet(BuildContext context, SavingsGoal goal) {
    final amountController = TextEditingController(text: '1000');
    final formKey = GlobalKey<FormState>();
    final presetAmounts = [500, 1000, 2500, 5000];

    String? selectedAccountId;

    ModernBottomSheet.show(
      context: context,
      title: 'Add Savings Deposit',
      subtitle: 'Contribute funds towards "${goal.name}".',
      child: Consumer(
        builder: (context, ref, child) {
          final accountsAsync = ref.watch(accountsProvider);

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Account Selector
                    accountsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => const SizedBox.shrink(),
                      data: (accounts) {
                        if (accounts.isEmpty) return const SizedBox.shrink();
                        selectedAccountId ??= accounts.first.id;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Deduct From Account',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: selectedAccountId,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.account_balance_wallet_outlined,
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
                              items: accounts.map((acc) {
                                return DropdownMenuItem<String>(
                                  value: acc.id,
                                  child: Text(
                                    acc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
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
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: presetAmounts.map((amt) {
                        return ActionChip(
                          avatar: const Icon(Icons.add_rounded, size: 16, color: Color(0xFF10B981)),
                          label: Text('₱${amt.toString()}'),
                          onPressed: () {
                            amountController.text = amt.toString();
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    ModernTextField(
                      controller: amountController,
                      label: 'Deposit Amount (₱)',
                      hint: '1000.00',
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Enter deposit amount';
                        if (double.tryParse(v) == null || (double.tryParse(v)! <= 0)) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                        final mutator = ref.read(transactionMutatorProvider);
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
                              content: Text('Added ₱${amount.toStringAsFixed(2)} to ${goal.name}! 🎉'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('Add Savings Deposit', style: TextStyle(fontWeight: FontWeight.bold)),
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
          );
        },
      ),
    );
  }

  void _showPurchaseCheckBottomSheet(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    PurchaseCheckResult? checkResult;
    bool isLoading = false;

    ModernBottomSheet.show(
      context: context,
      title: 'Can I Buy This? 🛍️📱',
      subtitle: 'Deterministic financial impact calculation on cash flow, bills, and threshold.',
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ModernTextField(
                  controller: titleController,
                  label: 'Item / Purchase Name',
                  hint: 'e.g. Smartphone, New Headphones, Concert Ticket',
                  prefixIcon: Icons.shopping_bag_outlined,
                  validator: (v) => (v?.trim().length ?? 0) > 0 ? null : 'Item name is required',
                ),
                const SizedBox(height: 14),

                ModernTextField(
                  controller: amountController,
                  label: 'Item Price (₱)',
                  hint: '5000.00',
                  prefixIcon: Icons.account_balance_wallet_outlined,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Enter item price';
                    if (double.tryParse(v) == null || (double.tryParse(v)! <= 0)) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setModalState(() => isLoading = true);
                          final title = titleController.text.trim();
                          final amount = double.tryParse(amountController.text.trim()) ?? 0.0;

                          try {
                            final mutator = ref.read(transactionMutatorProvider);
                            final result = await mutator.evaluatePurchaseCheck(
                              itemTitle: title,
                              amount: amount,
                            );
                            setModalState(() {
                              checkResult = result;
                              isLoading = false;
                            });
                          } catch (err) {
                            setModalState(() => isLoading = false);
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.analytics_outlined, size: 20),
                  label: Text(
                    isLoading ? 'Calculating Impact...' : 'Evaluate Affordability',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

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
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          // Sleek "Can I Buy This?" Icon Action Button right beside "+"
          Tooltip(
            message: 'Can I Buy This? (Purchase Check)',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _showPurchaseCheckBottomSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.2 : 0.1),
                    border: Border.all(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.3),
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
          const SizedBox(width: 8),
          Tooltip(
            message: 'Create Savings Goal',
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _showAddGoalBottomSheet(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.1),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF10B981),
        onRefresh: () async => ref.invalidate(goalsProvider),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            goalsAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              ),
              error: (err, _) => ModernCard(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading savings goals: $err'),
              ),
              data: (goals) {
                if (goals.isEmpty) {
                  return ModernCard(
                    padding: EdgeInsets.zero,
                    child: EmptyStateView(
                      title: 'No Savings Goals Yet',
                      message: 'Set target savings goals for your Emergency Fund, Tuition Fee, or a New Gadget.',
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
                        onDeposit: () => _showAddDepositBottomSheet(context, goal),
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
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF059669), Color(0xFF10B981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddGoalBottomSheet(context),
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'New Goal',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          tooltip: 'Create Goal',
        ),
      ),
    );
  }
}

// ─── Modern Redesigned Savings Goal Card ───────────────────────

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
    final progressPct = (goal.progress * 100).clamp(0.0, 100.0).toStringAsFixed(0);
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);

    return ModernCard(
      padding: const EdgeInsets.all(20),
      gradient: LinearGradient(
        colors: isDark
            ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
            : const [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row (Icon Avatar + Title + Deposit Chip) ─────────
          Row(
            children: [
              // Avatar Squircle
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.savings_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),

              // Title & Target Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Target: ₱${goal.targetAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Deposit Chip & Percentage Tag
              Row(
                children: [
                  InkWell(
                    onTap: onDeposit,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 14, color: Color(0xFF10B981)),
                          SizedBox(width: 3),
                          Text(
                            'Deposit',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$progressPct%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF059669),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── Metrics Row (Saved vs Remaining) ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${goal.currentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₱${remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ── Custom Gradient Progress Bar ───────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth;
              final filledWidth = barWidth * goal.progress.clamp(0.0, 1.0);

              return Container(
                height: 10,
                width: barWidth,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    height: 10,
                    width: filledWidth,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF10B981)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ── Goal Affordability Forecast Banner ─────────────────────
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
      cardColor = const Color(0xFF10B981);
      icon = Icons.check_circle_rounded;
    } else if (result.verdict == 'RISKY') {
      cardColor = const Color(0xFFF59E0B);
      icon = Icons.warning_rounded;
    } else {
      cardColor = const Color(0xFFEF4444);
      icon = Icons.cancel_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1.5),
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const Divider(height: 24),

          for (final reason in result.reasons) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: cardColor)),
                  Expanded(
                    child: Text(
                      reason,
                      style: const TextStyle(fontSize: 12, height: 1.3),
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

  const _GoalForecastBanner({
    required this.goal,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
    if (remaining <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.stars_rounded, size: 18, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Goal Completed! 🎉 You can fully afford this goal.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
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
      bannerColor = const Color(0xFF10B981);
      icon = Icons.check_circle_outline_rounded;
      statusTitle = goal.targetDate != null
          ? 'On Track to afford by ${_formatDateStr(goal.targetDate)}'
          : 'Can afford by ${_formatDateStr(earliestDate)}';
      statusDetail = reqMonthly != null && reqMonthly > 0
          ? 'Requires ~₱${reqMonthly.toStringAsFixed(0)}/month in net savings.'
          : 'Your current daily cash flow covers this goal on schedule.';
    } else if (canAfford == false) {
      bannerColor = const Color(0xFFF59E0B);
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
        color: bannerColor.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bannerColor.withValues(alpha: 0.25), width: 1),
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
