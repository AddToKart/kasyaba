import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dashboard_tokens.dart';

class DashboardMoreCard extends StatelessWidget {
  final List<SavingsGoal> goals;
  final List<BillItem> bills;
  final List<TransactionEntry> transactions;
  final VoidCallback onGoalsTap;
  final VoidCallback onBillsTap;
  final VoidCallback onTransactionsTap;

  const DashboardMoreCard({
    super.key,
    required this.goals,
    required this.bills,
    required this.transactions,
    required this.onGoalsTap,
    required this.onBillsTap,
    required this.onTransactionsTap,
  });

  String _goalsSubtitle() {
    if (goals.isEmpty) return 'No active goals · Set your next milestone';
    final topGoal = goals.first;
    final pct = (topGoal.progress * 100).clamp(0, 100).toInt();
    return '${goals.length} goal${goals.length == 1 ? "" : "s"} · ${topGoal.name} is $pct% funded';
  }

  String _billsSubtitle() {
    final unpaidBills = bills.where((b) => b.status != 'paid').toList();
    if (unpaidBills.isEmpty) return 'No upcoming bills';
    final nextBill = unpaidBills.first;
    return '${unpaidBills.length} upcoming bill${unpaidBills.length == 1 ? "" : "s"} · ${nextBill.name} due ${DateFormat('MMM d').format(nextBill.dueDate)}';
  }

  String _recentActivitySubtitle() {
    if (transactions.isEmpty) return 'No recent activity yet';
    final latest = transactions.first;
    final signedAmt = CurrencyFormatter.formatSigned(
      latest.amount,
      isExpense: latest.isExpense,
    );
    final dateStr = DateFormat('MMM d').format(latest.date);
    return '${latest.categoryName} $signedAmt · $dateStr';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title: "More"
        Text(
          'More',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: DashboardTokens.periwinkleGray,
          ),
        ),
        const SizedBox(height: 10),

        // Main Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 3),
          decoration: BoxDecoration(
            color: DashboardTokens.bigStone,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: DashboardTokens.poloBlue22,
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              // Row 1: Goals
              _MoreHubRow(
                title: 'Goals',
                subtitle: _goalsSubtitle(),
                onTap: onGoalsTap,
              ),

              // Divider 1
              Container(
                height: 1,
                color: DashboardTokens.poloBlue16,
              ),

              // Row 2: Bills
              _MoreHubRow(
                title: 'Bills',
                subtitle: _billsSubtitle(),
                onTap: onBillsTap,
              ),

              // Divider 2
              Container(
                height: 1,
                color: DashboardTokens.poloBlue16,
              ),

              // Row 3: Recent Activity
              _MoreHubRow(
                title: 'Recent activity',
                subtitle: _recentActivitySubtitle(),
                onTap: onTransactionsTap,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreHubRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreHubRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: DashboardTokens.periwinkleGray,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      color: DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SvgPicture.asset(
              'assets/images/dashboard_chevron_right.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                DashboardTokens.poloBlue,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
