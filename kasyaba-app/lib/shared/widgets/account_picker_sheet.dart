import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_color_scheme.dart';
import '../../core/providers/api_providers.dart';
import '../../core/utils/currency_formatter.dart';
import 'app_sheet.dart';

/// Token-styled wallet picker used by transfer mode, goal deposits, and any
/// other flow that needs to choose a source/target wallet.
///
/// Returns the picked [Account], or null when the user dismisses the sheet.
Future<Account?> showKasyabaAccountPicker({
  required BuildContext context,
  required List<Account> accounts,
  required String? selectedId,
  Map<String, double>? balances,
}) {
  if (accounts.isEmpty) return Future.value(null);

  return showKasyabaSheet<Account>(
    context: context,
    builder: (sheetContext) {
      final colors = sheetContext.kColors;
      return AppSheet(
        color: colors.card,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Wallet',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              itemCount: accounts.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: colors.divider),
              itemBuilder: (_, index) {
                final account = accounts[index];
                final isSelected = account.id == selectedId;
                final balance = balances?[account.id];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    account.name,
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isSelected
                          ? colors.success
                          : colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    account.type.toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    balance != null ? CurrencyFormatter.format(balance) : '-',
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.textSecondary,
                    ),
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(account),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
