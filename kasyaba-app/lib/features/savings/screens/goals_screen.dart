import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_motion.dart';
import '../../../core/errors/error_messages.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/deterministic_math.dart';
import '../../../shared/widgets/app_state_widgets.dart';
import '../../../shared/widgets/kasyaba_background.dart';
import '../../../shared/widgets/kasyaba_card.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/pill_button.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../dashboard/widgets/kasyaba_affordability_sheet.dart';
import '../widgets/goal_deposit_sheet.dart';

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
      body: KasyabaBackground(
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
                      SpringTouch(
                        scaleDown: 0.88,
                        onTap: () {
                          AppHaptics.lightImpact();
                          context.push('/goals/new');
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
                    loading: () => const Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        KasyabaLoadingSkeleton(lines: 3),
                        SizedBox(height: 14),
                        KasyabaLoadingSkeleton(lines: 2),
                        SizedBox(height: 14),
                        KasyabaLoadingSkeleton(lines: 2),
                      ],
                    ),
                    error: (err, _) => KasyabaErrorCard(
                      message: friendlyErrorMessage(
                        err,
                        fallback: 'Could not load your goals.',
                      ),
                      onRetry: () => ref.invalidate(goalsProvider),
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
                          FadeSlideEntrance.staggered(
                            index: 0,
                            child: KasyabaCard(
                              padding: const EdgeInsets.all(19),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total saved',
                                    style: GoogleFonts.dmSans(
                                      fontSize: 14,
                                      color: DashboardTokens
                                          .periwinkleGraySubtitle,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
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
                                          color: DashboardTokens
                                              .periwinkleGraySubtitle,
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
                                            constraints.maxWidth *
                                            overallProgress;
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: AnimatedContainer(
                                            duration: AppMotion.bouncy,
                                            curve: Curves.easeOutCubic,
                                            width: fillWidth,
                                            decoration: BoxDecoration(
                                              color: DashboardTokens.bermuda,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // ─── Empty state if no goals ───
                          if (goals.isEmpty)
                            KasyabaCard(
                              padding: EdgeInsets.zero,
                              child: KasyabaEmptyState(
                                icon: Icons.savings_outlined,
                                title: 'No savings goals yet',
                                message:
                                    'Create a goal for an emergency fund, gadget, or trip to track progress.',
                                action: PillButton(
                                  label: 'Add your first goal',
                                  onPressed: () => context.push('/goals/new'),
                                  height: 48,
                                  expand: false,
                                ),
                              ),
                            ),

                          // ─── Goals Cards (Figma Nodes 11:1995, 11:2017, 11:2040) ───
                          ...goals.asMap().entries.map((entry) {
                            final i = entry.key;
                            final goal = entry.value;
                            final progress = goal.progress;
                            final percent = (progress * 100).round();
                            final monthlyNeed = goalMonthlyNeed(goal);
                            final dateText = _formatTargetDate(goal.targetDate);
                            final bool? canAfford = goal.canAffordByTargetDate;
                            final statusLabel = canAfford == null
                                ? null
                                : (canAfford
                                      ? 'On track · $dateText'
                                      : 'Behind schedule · $dateText');
                            final statusColor = canAfford == true
                                ? DashboardTokens.bermuda
                                : DashboardTokens.apricot;

                            return FadeSlideEntrance.staggered(
                              index: 1 + i,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: KasyabaCard(
                                  padding: const EdgeInsets.all(19),
                                  onTap: () {
                                    AppHaptics.lightImpact();
                                    context.push(
                                      '/goals/${goal.id}',
                                      extra: goal,
                                    );
                                  },
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
                                                color:
                                                    DashboardTokens.poloBlue30,
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
                                                    fontWeight: FontWeight.w700,
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
                                            style:
                                                GoogleFonts.bricolageGrotesque(
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
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
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
                                                  statusLabel ?? dateText,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: statusLabel == null
                                                        ? DashboardTokens
                                                              .periwinkleGraySubtitle
                                                        : statusColor,
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
                                          PillButton(
                                            label: 'Deposit',
                                            variant:
                                                PillButtonVariant.secondary,
                                            height: 46,
                                            expand: false,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 19,
                                            ),
                                            borderRadius: 22,
                                            fontSize: 14,
                                            onPressed: () {
                                              AppHaptics.lightImpact();
                                              GoalDepositSheet.show(
                                                context,
                                                goal,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),

                          const SizedBox(height: 6),

                          // ─── Footer: Planning a purchase? Can I afford it? (Figma Node 11:2063) ───
                          FadeSlideEntrance.staggered(
                            index: 1 + goals.length,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Planning a purchase?\u00A0',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    color:
                                        DashboardTokens.periwinkleGraySubtitle,
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
}
