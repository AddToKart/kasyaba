import 'package:flutter/painting.dart';
import 'package:intl/intl.dart';

/// Central currency and tabular number formatter enforcing standard Philippine
/// Peso representation (₱#,##0.00) with monospace tabular figure alignment.
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _standard = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  /// Tabular font feature ensuring all digits align vertically in tables & cards
  static const TextStyle tabularStyle = TextStyle(
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const List<FontFeature> tabularFigures = [FontFeature.tabularFigures()];

  /// Standard currency formatting: ₱60,372.00 or -₱2,100.00
  static String format(num amount, {int? decimalDigits}) {
    if (decimalDigits != null && decimalDigits != 2) {
      final pattern = decimalDigits == 0 ? '#,##0' : '#,##0.${'0' * decimalDigits}';
      final formatted = NumberFormat(pattern, 'en_PH').format(amount.abs());
      return amount < 0 ? '-₱$formatted' : '₱$formatted';
    }
    if (amount < 0) {
      return '-₱${NumberFormat('#,##0.00', 'en_PH').format(amount.abs())}';
    }
    return _standard.format(amount);
  }

  /// Currency formatting with explicit plus/minus: +₱5,000.00 or -₱2,100.00
  static String formatSigned(num amount, {bool isExpense = false}) {
    final absFormatted = _standard.format(amount.abs());
    if (isExpense || amount < 0) {
      return '-$absFormatted';
    }
    return '+$absFormatted';
  }

  /// Compact currency formatting for space-constrained badges: ₱1.5K or ₱1.2M
  static String formatCompact(num amount) {
    if (amount.abs() >= 1000000) {
      final sign = amount < 0 ? '-' : '';
      return '$sign₱${(amount.abs() / 1000000).toStringAsFixed(1)}M';
    }
    if (amount.abs() >= 10000) {
      final sign = amount < 0 ? '-' : '';
      return '$sign₱${(amount.abs() / 1000).toStringAsFixed(1)}K';
    }
    return format(amount);
  }
}
