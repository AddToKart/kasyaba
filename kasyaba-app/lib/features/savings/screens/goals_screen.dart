import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../dashboard/widgets/kasyaba_affordability_sheet.dart';
import '../widgets/goal_deposit_sheet.dart';
import 'create_goal_screen.dart';
import 'goal_detail_screen.dart';

/// ─────────────────────────────────────────────────────────────
///  Goals Screen (Figma Node 42:6585)
/// ─────────────────────────────────────────────────────────────
class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  Widget _buildGoalIcon(String name) {
    final lower = name.toLowerCase();
    String? assetPath;
    if (lower.contains('gadget') ||
        lower.contains('phone') ||
        lower.contains('laptop') ||
        lower.contains('tech') ||
        lower.contains('device')) {
      assetPath = 'assets/images/goal_gadget.svg';
    } else if (lower.contains('vacation') ||
        lower.contains('trip') ||
        lower.contains('travel') ||
        lower.contains('holiday') ||
        lower.contains('flight')) {
      assetPath = 'assets/images/goal_vacation.svg';
    } else if (lower.contains('emergency') ||
        lower.contains('fund') ||
        lower.contains('shield') ||
        lower.contains('medical') ||
        lower.contains('buffer')) {
      assetPath = 'assets/images/goal_emergency.svg';
    }

    if (assetPath != null) {
      return SvgPicture.asset(
        assetPath,
        width: 22,
        height: 22,
        colorFilter: const ColorFilter.mode(
          DashboardTokens.periwinkleGray,
          BlendMode.srcIn,
        ),
      );
    }

    return const Icon(
      Icons.savings_outlined,
      size: 22,
      color: DashboardTokens.periwinkleGray,
    );
  }

  double _calculateMonthlyNeed(SavingsGoal goal) {
    final remaining = (goal.targetAmount - goal.currentAmount).clamp(0.0, double.infinity);
    if (remaining <= 0) return 0.0;
    if (goal.targetDate == null) return remaining;

    final target = DateTime.tryParse(goal.targetDate!);
    if (target == null) return remaining;

    final now = DateTime.now();
    final daysUntil = target.difference(now).inDays;
    if (daysUntil <= 0) return remaining;

    return (remaining / daysUntil) * 30.0;
  }

  String _formatTargetDate(String? raw) {
    if (raw == null) return 'Flexible timeline';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    return DateFormat('MMM d, yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.8, -1.0),
            radius: 1.2,
            colors: [
              const Color(0xFF4F7596).withValues(alpha: 0.67),
              DashboardTokens.ebony,
            ],
            stops: const [0.0, 0.7],
          ),
          color: DashboardTokens.ebony,
        ),
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: DashboardTokens.bermuda,
            backgroundColor: DashboardTokens.bigStone,
            onRefresh: () async {
              ref.invalidate(goalsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ─── Header: Goals & Add Button (Figma Node 11:1981) ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Goals',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: DashboardTokens.periwinkleGray,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          AppHaptics.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateGoalScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(
                            color: DashboardTokens.periwinkleGray,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: SvgPicture.asset(
                            'assets/images/goal_plus.svg',
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(
                              DashboardTokens.ebony,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  goalsAsync.when(
                    loading: () => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeroSkeleton(),
                        const SizedBox(height: 14),
                        _buildGoalCardSkeleton(),
                        const SizedBox(height: 14),
                        _buildGoalCardSkeleton(),
                      ],
                    ),
                    error: (err, _) => Container(
                      padding: const EdgeInsets.all(24),
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
                          const Icon(
                            Icons.error_outline,
                            color: DashboardTokens.apricot,
                            size: 36,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Failed to load goals: $err',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                              color: DashboardTokens.periwinkleGraySubtitle,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: DashboardTokens.periwinkleGray,
                              foregroundColor: DashboardTokens.ebony,
                            ),
                            onPressed: () => ref.invalidate(goalsProvider),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (goals) {
                      final totalSaved = goals.fold<double>(
                        0.0,
                        (sum, g) => sum + g.currentAmount,
                      );
                      final totalTarget = goals.fold<double>(
                        0.0,
                        (sum, g) => sum + g.targetAmount,
                      );
                      final overallProgress = totalTarget > 0
                          ? (totalSaved / totalTarget).clamp(0.0, 1.0)
                          : 0.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ─── Total Saved Hero Card (Figma Node 11:1987) ───
                          Container(
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
                                Text(
                                  'Total saved',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color: DashboardTokens.periwinkleGraySubtitle,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${CurrencyFormatter.format(totalSaved)} ',
                                      style: GoogleFonts.bricolageGrotesque(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: DashboardTokens.periwinkleGray,
                                      ),
                                    ),
                                    Text(
                                      'of ${CurrencyFormatter.format(totalTarget)}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: DashboardTokens.periwinkleGraySubtitle,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // 8px progress bar
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: DashboardTokens.poloBlue20,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final fillWidth =
                                          constraints.maxWidth * overallProgress;
                                      return Align(
                                        alignment: Alignment.centerLeft,
                                        child: AnimatedContainer(
                                          duration: AppMotion.bouncy,
                                          curve: Curves.easeOutCubic,
                                          width: fillWidth,
                                          decoration: BoxDecoration(
                                            color: DashboardTokens.bermuda,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ─── Empty state if no goals ───
                          if (goals.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 36,
                              ),
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
                                  SvgPicture.asset(
                                    'assets/images/goal_emergency.svg',
                                    width: 44,
                                    height: 44,
                                    colorFilter: const ColorFilter.mode(
                                      DashboardTokens.periwinkleGraySubtitle,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No savings goals yet',
                                    style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: DashboardTokens.periwinkleGray,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create a goal for an emergency fund, gadget, or trip to track progress.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: DashboardTokens.periwinkleGraySubtitle,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: DashboardTokens.periwinkleGray,
                                      foregroundColor: DashboardTokens.ebony,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const CreateGoalScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'Add your first goal',
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // ─── Goals Cards (Figma Nodes 11:1995, 11:2017, 11:2040) ───
                          ...goals.map((goal) {
                            final progress = goal.targetAmount > 0
                                ? (goal.currentAmount / goal.targetAmount)
                                    .clamp(0.0, 1.0)
                                : 0.0;
                            final percent = (progress * 100).round();
                            final monthlyNeed = _calculateMonthlyNeed(goal);
                            final dateText = _formatTargetDate(goal.targetDate);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () {
                                    AppHaptics.lightImpact();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => GoalDetailScreen(
                                          goalId: goal.id,
                                          initialGoal: goal,
                                        ),
                                      ),
                                    );
                                  },
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        // Row 1: Squircle Icon + Title + Percent
                                        Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(23),
                                                border: Border.all(
                                                  color: DashboardTokens.poloBlue30,
                                                  width: 1,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: _buildGoalIcon(goal.name),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    goal.name,
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: DashboardTokens
                                                          .periwinkleGray,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${CurrencyFormatter.format(goal.currentAmount)} of ${CurrencyFormatter.format(goal.targetAmount)}',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 14,
                                                      color: DashboardTokens
                                                          .periwinkleGraySubtitle,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              '$percent%',
                                              style: GoogleFonts
                                                  .bricolageGrotesque(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: DashboardTokens
                                                    .periwinkleGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),

                                        // 8px progress bar
                                        Container(
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: DashboardTokens.poloBlue20,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final fillWidth =
                                                  constraints.maxWidth * progress;
                                              return Align(
                                                alignment: Alignment.centerLeft,
                                                child: AnimatedContainer(
                                                  duration: AppMotion.bouncy,
                                                  curve: Curves.easeOutCubic,
                                                  width: fillWidth,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        DashboardTokens.bermuda,
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        const SizedBox(height: 12),

                                        // Row 2: Status & Need / Deposit button
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'On track · $dateText',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: DashboardTokens
                                                          .bermuda,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Needs about ${CurrencyFormatter.format(monthlyNeed)} a month',
                                                    style: GoogleFonts.dmSans(
                                                      fontSize: 13,
                                                      color: DashboardTokens
                                                          .periwinkleGraySubtitle,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Deposit button (Figma Node 11:2015)
                                            GestureDetector(
                                              onTap: () {
                                                AppHaptics.lightImpact();
                                                GoalDepositSheet.show(
                                                  context,
                                                  goal,
                                                );
                                              },
                                              child: Container(
                                                height: 46,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 19,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(22),
                                                  border: Border.all(
                                                    color: DashboardTokens
                                                        .kashmirBlue,
                                                    width: 1,
                                                  ),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'Deposit',
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: DashboardTokens
                                                        .periwinkleGray,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 6),

                          // ─── Footer: Planning a purchase? Can I afford it? (Figma Node 11:2063) ───
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Planning a purchase?\u00A0',
                                style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: DashboardTokens.periwinkleGraySubtitle,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  AppHaptics.lightImpact();
                                  // Open affordability bottom sheet or route to forecast
                                  KasyabaAffordabilitySheet.show(context);
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: DashboardTokens.kashmirBlue,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    'Can I afford it?',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: DashboardTokens.periwinkleGray,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: DashboardTokens.bermuda,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildGoalCardSkeleton() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: DashboardTokens.bigStone,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: DashboardTokens.poloBlue22, width: 1),
      ),
    );
  }
}
