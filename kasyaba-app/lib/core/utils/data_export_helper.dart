import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/api_providers.dart';

/// Result of validating a Kasyaba backup JSON payload.
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final DateTime? exportedAt;
  final String? userEmail;
  final String? userDisplayName;
  final int accountCount;
  final int expenseCount;
  final int incomeCount;
  final int transferCount;
  final int categoryCount;
  final int goalCount;
  final int budgetCount;
  final int billCount;
  final Map<String, dynamic>? sanitizedPayload;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.exportedAt,
    this.userEmail,
    this.userDisplayName,
    this.accountCount = 0,
    this.expenseCount = 0,
    this.incomeCount = 0,
    this.transferCount = 0,
    this.categoryCount = 0,
    this.goalCount = 0,
    this.budgetCount = 0,
    this.billCount = 0,
    this.sanitizedPayload,
  });

  int get totalRecordsCount =>
      accountCount +
      expenseCount +
      incomeCount +
      transferCount +
      categoryCount +
      goalCount +
      budgetCount +
      billCount;
}

class DataExportHelper {
  /// Generates an RFC 4180-compliant CSV string representing all transactions.
  static String generateTransactionsCsv({
    required List<TransactionEntry> transactions,
    required Map<String, String> accountNames,
  }) {
    final buffer = StringBuffer();
    // Header
    buffer.writeln(
      'Date,Type,Description,Category,Amount (PHP),Account / Wallet,Notes,Status',
    );

    for (final t in transactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.date);
      final typeStr = t.type.toUpperCase();
      final desc = escapeCsvField(t.title);
      final category = escapeCsvField(t.categoryName);
      final signedAmount = t.isTransfer
          ? t.amount.toStringAsFixed(2)
          : (t.isExpense
              ? '-${t.amount.toStringAsFixed(2)}'
              : '+${t.amount.toStringAsFixed(2)}');
      final account = escapeCsvField(
        accountNames[t.accountId] ?? 'Default Wallet',
      );
      final notes = escapeCsvField(t.notes ?? '');
      final status = t.status.toUpperCase();

      buffer.writeln(
        '$dateStr,$typeStr,$desc,$category,$signedAmount,$account,$notes,$status',
      );
    }

    return buffer.toString();
  }

  /// Escapes a CSV field according to RFC 4180.
  static String escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Validates a raw JSON string or map against Kasyaba's backup schema.
  static BackupValidationResult validateBackup(dynamic rawInput) {
    Map<String, dynamic> json;
    if (rawInput is String) {
      try {
        final decoded = jsonDecode(rawInput);
        if (decoded is! Map<String, dynamic>) {
          return const BackupValidationResult(
            isValid: false,
            errorMessage: 'Backup must be a JSON object.',
          );
        }
        json = decoded;
      } catch (e) {
        return BackupValidationResult(
          isValid: false,
          errorMessage: 'Invalid JSON format: $e',
        );
      }
    } else if (rawInput is Map<String, dynamic>) {
      json = rawInput;
    } else {
      return const BackupValidationResult(
        isValid: false,
        errorMessage: 'Invalid backup data type.',
      );
    }

    // Envelope can be { "exportedAt": ..., "user": { ... } } or direct collections
    final Map<String, dynamic> userMap =
        json['user'] is Map<String, dynamic>
            ? (json['user'] as Map<String, dynamic>)
            : json;

    DateTime? exportedAt;
    if (json['exportedAt'] != null) {
      exportedAt = DateTime.tryParse(json['exportedAt'].toString());
    }

    final email = userMap['email']?.toString();
    final displayName = userMap['displayName']?.toString();

    // Helper to safely extract list counts
    int countOf(List<String> keys) {
      for (final k in keys) {
        final val = userMap[k] ?? json[k];
        if (val is List) return val.length;
      }
      return 0;
    }

    final accountCount = countOf(['financialAccounts', 'accounts']);
    final expenseCount = countOf(['expenseEntries', 'expenses']);
    final incomeCount = countOf(['incomeEntries', 'income']);
    final transferCount = countOf(['transfers', 'accountTransfers']);
    final categoryCount = countOf(['expenseCategories', 'categories']);
    final goalCount = countOf(['savingsGoals', 'goals']);
    final budgetCount = countOf(['budgets']);
    final billCount = countOf(['billTemplates', 'bills']);

    final totalCount =
        accountCount +
        expenseCount +
        incomeCount +
        transferCount +
        categoryCount +
        goalCount +
        budgetCount +
        billCount;

    // Check if it's completely empty or unrelated JSON
    if (totalCount == 0 && email == null && json['exportedAt'] == null) {
      return const BackupValidationResult(
        isValid: false,
        errorMessage:
            'Unrecognized backup schema. No accounts, transactions, or user records found.',
      );
    }

    return BackupValidationResult(
      isValid: true,
      exportedAt: exportedAt,
      userEmail: email,
      userDisplayName: displayName,
      accountCount: accountCount,
      expenseCount: expenseCount,
      incomeCount: incomeCount,
      transferCount: transferCount,
      categoryCount: categoryCount,
      goalCount: goalCount,
      budgetCount: budgetCount,
      billCount: billCount,
      sanitizedPayload: json,
    );
  }

  /// Writes content to a file in the app documents directory and returns the file path.
  static Future<String> saveToFile({
    required String filename,
    required String content,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file.path;
  }
}
