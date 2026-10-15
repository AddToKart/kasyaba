import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/modern_card.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  final _incomeController = TextEditingController();
  final _expenseController = TextEditingController();
  final _savingsController = TextEditingController();

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  Future<void> _showScenarioLab(
    BuildContext context,
    PlanningOverview overview,
  ) async {
    _incomeController.clear();
    _expenseController.clear();
    _savingsController.clear();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: AppColors.surface800,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) {
          double readAmount(TextEditingController controller) {
            return double.tryParse(controller.text.trim()) ?? 0;
          }

          final adjustedClosing = overview.projectedClosingBalance +
              readAmount(_incomeController) -
              readAmount(_expenseController) -
              readAmount(_savingsController);
          final adjustedBuffer =
              adjustedClosing - overview.minimumBalanceThreshold;
          final adjustedDaily = adjustedBuffer > 0
              ? adjustedBuffer / overview.daysInWindow
              : 0.0;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                8,
                20,
                MediaQuery.viewInsetsOf(context).bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Scenario Lab',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Test a decision before it touches your real records. Nothing here is saved.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    _ScenarioAmountField(
                      controller: _incomeController,
                      label: 'One-time extra income',
                      icon: Icons.add_circle_outline_rounded,
                      color: AppColors.income,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _ScenarioAmountField(
                      controller: _expenseController,
                      label: 'One-time extra expense',
                      icon: Icons.remove_circle_outline_rounded,
                      color: AppColors.expense,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _ScenarioAmountField(
                      controller: _savingsController,
                      label: 'Extra savings reserve',
                      icon: Icons.savings_outlined,
                      color: AppColors.info,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    ModernCard(
                      backgroundColor: AppColors.surface700,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIMULATED OUTCOME',
                            style: TextStyle(
                              color: AppColors.gold400,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${_money(adjustedClosing)} projected close',
                            style: const TextStyle(
                              color: AppColors.textDark,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_money(adjustedDaily)} safe to spend per day',
                            style: const TextStyle(
                              color: AppColors.emerald400,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            adjustedBuffer < 0
                                ? 'This scenario breaks your safety buffer by ${_money(adjustedBuffer.abs())}.'
                                : 'This leaves ${_money(adjustedBuffer)} above your safety buffer.',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              height: 1.4,
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
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planningAsync = ref.watch(planningProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.obsidian,
      appBar: AppBar(
        title: const Text('Planning Lab'),
        actions: [
          IconButton(
            tooltip: 'Refresh plan',
            onPressed: () => ref.invalidate(planningProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: planningAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ModernCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.expense, size: 34),
                  const SizedBox(height: 12),
                  Text('Could not load your plan', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    friendlyErrorMessage(
                      error,
                      fallback: 'Something went wrong while loading your plan.',
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: () => ref.invalidate(planningProvider),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          ),
        ),
        data: (overview) => RefreshIndicator(
          color: AppColors.emerald500,
          onRefresh: () async {
            ref.invalidate(planningProvider);
            await ref.read(planningProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              _PlanningHero(
                overview: overview,
                onScenarioTap: () => _showScenarioLab(context, overview),
              ),
              const SizedBox(height: 14),
              _PlanningMetricRow(overview: overview),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cash-flow runway', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  Text(
                    '${DateFormat('MMM d').format(overview.from)} – ${DateFormat('MMM d').format(overview.to)}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...overview.days.map((day) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PlanningDayTile(day: day),
                  )),
              const SizedBox(height: 10),
              ModernCard(
                backgroundColor: AppColors.surface900,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.calculate_outlined, color: AppColors.gold400, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        overview.calculationNote,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.45),
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

class _PlanningHero extends StatelessWidget {
  final PlanningOverview overview;
  final VoidCallback onScenarioTap;

  const _PlanningHero({required this.overview, required this.onScenarioTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(overview.status);
    return ModernCard(
      gradient: AppColors.gradientHeroCard,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MANUAL CASH-FLOW PLAN',
                style: TextStyle(color: AppColors.gold400, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(overview.status), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _money(overview.safeToSpendPerDay),
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
          const Text('safe to spend per day', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 18),
          Text(
            'Projected close: ${_money(overview.projectedClosingBalance)} after scheduled activity',
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w700,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Planning window: ${overview.daysInWindow} days • Buffer: ${_money(overview.minimumBalanceThreshold)} protected',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onScenarioTap,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Open Scenario Lab'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.gold300, side: const BorderSide(color: AppColors.gold500)),
          ),
        ],
      ),
    );
  }
}

class _PlanningMetricRow extends StatelessWidget {
  final PlanningOverview overview;

  const _PlanningMetricRow({required this.overview});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _PlanningMetric(label: 'Starting', value: overview.currentBalance, color: AppColors.info)),
        const SizedBox(width: 8),
        Expanded(child: _PlanningMetric(label: 'Committed', value: overview.committedOutflow, color: AppColors.expense)),
        const SizedBox(width: 8),
        Expanded(child: _PlanningMetric(label: 'Income', value: overview.totalPlannedIncome, color: AppColors.income)),
      ],
    );
  }
}

class _PlanningMetric extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PlanningMetric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      backgroundColor: AppColors.surface800,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 5),
          Text(
            _money(value),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanningDayTile extends StatelessWidget {
  final PlanningDay day;

  const _PlanningDayTile({required this.day});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(day.pressure);
    final eventParts = <String>[];
    if (day.income > 0) eventParts.add('+${_money(day.income)} income');
    if (day.expenses > 0) eventParts.add('-${_money(day.expenses)} planned');
    if (day.bills > 0) eventParts.add('-${_money(day.bills)} bills');
    if (eventParts.isEmpty) eventParts.add('No scheduled activity');

    return ModernCard(
      backgroundColor: AppColors.surface800,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(width: 4, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 12),
          SizedBox(
            width: 54,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEE').format(day.date), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                Text(DateFormat('MMM d').format(day.date), style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(eventParts.join(' • '), style: const TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.35))),
          const SizedBox(width: 8),
          Text(
            _money(day.projectedBalance),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              fontFeatures: CurrencyFormatter.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final ValueChanged<String> onChanged;

  const _ScenarioAmountField({required this.controller, required this.label, required this.icon, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        prefixText: '₱ ',
      ),
    );
  }
}

Color _statusColor(String status) {
  return switch (status) {
    'risk' => AppColors.expense,
    'watch' => AppColors.warning,
    _ => AppColors.emerald400,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'risk' => 'AT RISK',
    'watch' => 'WATCH',
    _ => 'ON TRACK',
  };
}

String _money(double value) => CurrencyFormatter.format(value);
