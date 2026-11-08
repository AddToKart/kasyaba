// CSV export pagination regression coverage.
//
// The server rejects `limit` values above 100. The CSV sheet must therefore
// walk /transactions at the 100-row cap, follow `meta.total`, and stop once all
// rows have been collected. These tests use the shared QA harness so the real
// BackupExportScreen -> export sheet flow is exercised without network access.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/settings/screens/backup_export_screen.dart';
import 'package:kasyaba/shared/widgets/app_state_widgets.dart';

import 'support/qa_harness.dart';

const int _qaTotalTransactions = 150;
const int _qaServerPageCap = 100;

/// A row shaped like the API payload consumed by the CSV sheet mapper
/// (`_mapTransaction` in data_backup_sheets.dart), including the keys also
/// required by TransactionEntry.fromJson for parity with other clients.
Map<String, dynamic> _qaTransactionJson(int index) {
  final day = (index % 28) + 1;
  return <String, dynamic>{
    'id': 'tx-${index.toString().padLeft(3, '0')}',
    'title': 'QA Transaction $index',
    'amount': 100 + index,
    'isExpense': index.isEven,
    'type': index.isEven ? 'expense' : 'income',
    'date': '2026-10-${day.toString().padLeft(2, '0')}',
    'categoryName': 'QA Category',
    'status': 'posted',
    'accountId': qaAccountId,
    'notes': 'note $index',
  };
}

void main() {
  testWidgets(
    'CSV export pages /transactions at 100 rows and exports all 150 rows',
    (tester) async {
      final harness = QaHarness();

      harness.adapter.responder = (request) {
        if (request.isGet && request.path == '/transactions') {
          final page =
              int.tryParse(request.queryParameters['page']?.toString() ?? '') ??
              1;
          final limit =
              int.tryParse(
                request.queryParameters['limit']?.toString() ?? '',
              ) ??
              50;
          final start = (page - 1) * limit;
          final remaining = _qaTotalTransactions - start;
          final count = remaining < 0
              ? 0
              : (remaining > limit ? limit : remaining);

          return QaHttpResponse.ok(<String, dynamic>{
            'data': <dynamic>[
              for (var index = start; index < start + count; index++)
                _qaTransactionJson(index),
            ],
            'meta': <String, dynamic>{'total': _qaTotalTransactions},
          });
        }
        if (request.isGet && request.path == '/auth/me') {
          return QaHttpResponse.ok(<String, dynamic>{
            'data': harness.adapter.authProfile,
          });
        }
        return QaHttpResponse.ok(<String, dynamic>{
          'data': <String, dynamic>{},
        });
      };

      await harness.pumpScreen(
        tester,
        const BackupExportScreen(),
        overrides: <Override>[
          accountsProvider.overrideWith(
            (ref) async => const <Account>[qaDefaultAccount],
          ),
        ],
      );

      expect(find.text('Export transactions'), findsOneWidget);
      await tester.tap(find.text('Export transactions'));
      await qaSettle(tester);

      final transactionCalls = harness.adapter.calls(
        'GET',
        '/transactions',
      );

      expect(
        transactionCalls,
        hasLength(2),
        reason: '150 rows at the 100-row cap must take exactly two pages.',
      );
      expect(
        transactionCalls.map((call) => call.queryParameters['page']).toList(),
        <Object?>[1, 2],
        reason: 'The sheet must request pages 1 and 2 in order.',
      );
      expect(
        transactionCalls.map((call) => call.queryParameters['limit']).toList(),
        <Object?>[_qaServerPageCap, _qaServerPageCap],
        reason: 'Every request must use the server-safe 100-row page size.',
      );
      expect(
        transactionCalls.every(
          (call) => call.queryParameters['limit'] != 500,
        ),
        isTrue,
        reason: 'The legacy 500-row request must never be sent.',
      );

      // The sheet renders `transactions.length`, proving every fetched row was
      // parsed and neither page was dropped.
      expect(find.text('$_qaTotalTransactions entries'), findsOneWidget);
      expect(find.text('Total Transactions:'), findsOneWidget);
      expect(find.text('SPREADSHEET READY'), findsOneWidget);
      expect(find.text('Save CSV File to Device'), findsOneWidget);
      expect(
        find.byType(KasyabaErrorCard),
        findsNothing,
        reason: 'A clean two-page export must not surface an error card.',
      );
    },
  );
}
