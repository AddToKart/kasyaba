import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/utils/currency_formatter.dart';
import 'dashboard_tokens.dart';

class DashboardMoreCard extends StatelessWidget {
  final AsyncValue<List<SavingsGoal>> goals;
  final AsyncValue<List<BillItem>> bills;
  final AsyncValue<List<TransactionEntry>> transactions;
  final VoidCallback onGoalsTap;
  final VoidCallback onBillsTap;
  final VoidCallback onTransactionsTap;
  final VoidCallback? onRetryGoals;
  final VoidCallback? onRetryBills;
  final VoidCallback? onRetryTransactions;

  const DashboardMoreCard({
    super.key,
    required this.goals,
    required this.bills,
    required this.transactions,
    required this.onGoalsTap,
    required this.onBillsTap,
    required this.onTransactionsTap,
    this.onRetryGoals,
    this.onRetryBills,
    this.onRetryTransactions,
  });

  String _goalsSubtitle() {
    return goals.when(
      loading: () => 'Loading goals…',
      error: (_, _) => 'Could not load goals',
      data: (items) {
        if (items.isEmpty) return 'No active goals · Set your next milestone';
        final topGoal = items.first;
        final pct = (topGoal.progress * 100).clamp(0, 100).toInt();
        return '${items.length} goal${items.length == 1 ? "" : "s"} · ${topGoal.name} is $pct% funded';
      },
    );
  }

  String _billsSubtitle() {
    return bills.when(
      loading: () => 'Loading bills…',
      error: (_, _) => 'Could not load bills',
      data: (items) {
        final unpaidBills = items.where((b) => b.status != 'paid').toList();
        if (unpaidBills.isEmpty) return 'No upcoming bills';
        final nextBill = unpaidBills.first;
        return '${unpaidBills.length} upcoming bill${unpaidBills.length == 1 ? "" : "s"} · ${nextBill.name} due ${DateFormat('MMM d').format(nextBill.dueDate)}';
      },
    );
  }

  String _recentActivitySubtitle() {
    return transactions.when(
      loading: () => 'Loading recent activity…',
      error: (_, _) => 'Could not load recent activity',
      data: (items) {
        if (items.isEmpty) return 'No recent activity yet';
        final latest = items.first;
        final signedAmt = CurrencyFormatter.formatSigned(
          latest.amount,
          isExpense: latest.isExpense,
        );
        final dateStr = DateFormat('MMM d').format(latest.date);
        return '${latest.categoryName} $signedAmt · $dateStr';
      },
    );
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
            border: Border.all(color: DashboardTokens.poloBlue22, width: 1.0),
          ),
          child: Column(
            children: [
              // Row 1: Goals
              _MoreHubRow(
                title: 'Goals',
                subtitle: _goalsSubtitle(),
                isLoading: goals.isLoading,
                isError: goals.hasError,
                onRetry: onRetryGoals,
                onTap: onGoalsTap,
              ),

              // Divider 1
              Container(height: 1, color: DashboardTokens.poloBlue16),

              // Row 2: Bills
              _MoreHubRow(
                title: 'Bills',
                subtitle: _billsSubtitle(),
                isLoading: bills.isLoading,
                isError: bills.hasError,
                onRetry: onRetryBills,
                onTap: onBillsTap,
              ),

              // Divider 2
              Container(height: 1, color: DashboardTokens.poloBlue16),

              // Row 3: Recent Activity
              _MoreHubRow(
                title: 'Recent activity',
                subtitle: _recentActivitySubtitle(),
                isLoading: transactions.isLoading,
                isError: transactions.hasError,
                onRetry: onRetryTransactions,
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
  final bool isLoading;
  final bool isError;
  final VoidCallback? onRetry;

  const _MoreHubRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLoading = false,
    this.isError = false,
    this.onRetry,
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
                      color: isError
                          ? DashboardTokens.apricot
                          : DashboardTokens.periwinkleGraySubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DashboardTokens.periwinkleGraySubtitle,
                ),
              )
            else if (isError && onRetry != null)
              GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: DashboardTokens.apricot,
                  ),
                ),
              )
            else
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
