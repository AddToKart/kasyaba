import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/bills/screens/bills_screen.dart';

BillItem _bill({String status = 'upcoming', required DateTime dueDate}) {
  return BillItem(
    id: 'bill-1',
    name: 'Test bill',
    amount: 100.0,
    dueDate: dueDate,
    status: status,
  );
}

void main() {
  final today = DateTime(2026, 11, 8);

  group('resolveBillDisplayStatus', () {
    test('keeps server paid authoritative even when due date is past', () {
      expect(
        resolveBillDisplayStatus(
          _bill(status: 'paid', dueDate: DateTime(2026, 11, 1)),
          today,
        ),
        BillDisplayStatus.paid,
      );
    });

    test(
      'keeps server cancelled authoritative even when due date is future',
      () {
        expect(
          resolveBillDisplayStatus(
            _bill(status: 'cancelled', dueDate: DateTime(2026, 11, 20)),
            today,
          ),
          BillDisplayStatus.cancelled,
        );
      },
    );

    test('computes overdue from the local calendar day', () {
      expect(
        resolveBillDisplayStatus(
          _bill(dueDate: DateTime(2026, 11, 7, 23, 59)),
          today,
        ),
        BillDisplayStatus.overdue,
      );
    });

    test('computes due today using a date-only comparison', () {
      expect(
        resolveBillDisplayStatus(
          _bill(dueDate: DateTime(2026, 11, 8, 23, 59)),
          today,
        ),
        BillDisplayStatus.dueToday,
      );
    });

    test('computes upcoming from the local calendar day', () {
      expect(
        resolveBillDisplayStatus(
          _bill(dueDate: DateTime(2026, 11, 9, 0, 1)),
          today,
        ),
        BillDisplayStatus.upcoming,
      );
    });

    test('recomputes stale server overdue status from the due date', () {
      expect(
        resolveBillDisplayStatus(
          _bill(status: 'overdue', dueDate: DateTime(2026, 11, 12)),
          today,
        ),
        BillDisplayStatus.upcoming,
      );
    });

    test('normalizes status casing and whitespace', () {
      expect(
        resolveBillDisplayStatus(
          _bill(status: ' CANCELLED ', dueDate: DateTime(2026, 11, 12)),
          today,
        ),
        BillDisplayStatus.cancelled,
      );
    });
  });

  group('billDisplayStatusLabel', () {
    test('uses neutral, consistent labels for every state', () {
      expect(billDisplayStatusLabel(BillDisplayStatus.paid), 'Paid');
      expect(billDisplayStatusLabel(BillDisplayStatus.cancelled), 'Cancelled');
      expect(billDisplayStatusLabel(BillDisplayStatus.overdue), 'Overdue');
      expect(billDisplayStatusLabel(BillDisplayStatus.dueToday), 'Due today');
      expect(billDisplayStatusLabel(BillDisplayStatus.upcoming), 'Upcoming');
    });
  });
}
