import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/core/providers/api_providers.dart';

void main() {
  group('BillItem.fromJson', () {
    test(
      'reads category, recurrence, and reminder lead days from template',
      () {
        final bill = BillItem.fromJson({
          'id': 'bill-1',
          'name': 'Rent',
          'amount': '1500.50',
          'dueDate': '2026-11-05',
          'status': 'upcoming',
          'template': {
            'categoryId': 'cat-rent',
            'recurrence': 'monthly',
            'reminderLeadDays': 3,
          },
        });

        expect(bill.id, 'bill-1');
        expect(bill.name, 'Rent');
        expect(bill.amount, 1500.50);
        expect(bill.dueDate, DateTime(2026, 11, 5));
        expect(bill.status, 'upcoming');
        expect(bill.categoryId, 'cat-rent');
        expect(bill.recurrence, 'monthly');
        expect(bill.reminderLeadDays, 3);
      },
    );

    test('prefers top-level fields over nested template fields', () {
      final bill = BillItem.fromJson({
        'id': 'bill-2',
        'name': 'Internet',
        'amount': 1299.50,
        'dueDate': '2026-11-06',
        'categoryId': 'cat-top-level',
        'recurrence': 'weekly',
        'reminderLeadDays': 2,
        'template': {
          'categoryId': 'cat-template',
          'recurrence': 'monthly',
          'reminderLeadDays': 7,
        },
      });

      expect(bill.categoryId, 'cat-top-level');
      expect(bill.recurrence, 'weekly');
      expect(bill.reminderLeadDays, 2);
    });

    test('defaults reminderLeadDays to 1 when absent everywhere', () {
      final withoutTemplate = BillItem.fromJson({
        'id': 'bill-3',
        'name': 'Water',
        'amount': '500.00',
        'dueDate': '2026-11-07',
      });

      final withIncompleteTemplate = BillItem.fromJson({
        'id': 'bill-4',
        'name': 'Electricity',
        'amount': '900.00',
        'dueDate': '2026-11-08',
        'template': {'categoryId': 'cat-utilities'},
      });

      expect(withoutTemplate.reminderLeadDays, 1);
      expect(withIncompleteTemplate.reminderLeadDays, 1);
    });
  });

  group('SavingsGoal.fromJson', () {
    test('defaults missing or null currentAmount to 0.0', () {
      final missing = SavingsGoal.fromJson({
        'id': 'goal-1',
        'name': 'Vacation',
        'targetAmount': '5000.00',
      });
      final explicitNull = SavingsGoal.fromJson({
        'id': 'goal-2',
        'name': 'Laptop',
        'targetAmount': 80000,
        'currentAmount': null,
      });

      expect(missing.currentAmount, 0.0);
      expect(explicitNull.currentAmount, 0.0);
      expect(missing.progress, 0.0);
    });

    test('falls back to savedAmount when currentAmount is absent', () {
      final goal = SavingsGoal.fromJson({
        'id': 'goal-3',
        'name': 'Emergency Fund',
        'targetAmount': '10000.00',
        'savedAmount': '2500.00',
      });

      expect(goal.currentAmount, 2500.0);
      expect(goal.progress, 0.25);
    });

    test('parses string target and current amounts', () {
      final goal = SavingsGoal.fromJson({
        'id': 'goal-4',
        'name': 'Phone',
        'targetAmount': '30000.00',
        'currentAmount': '12000.00',
      });

      expect(goal.targetAmount, 30000.0);
      expect(goal.currentAmount, 12000.0);
      expect(goal.progress, 0.4);
    });

    test('clamps progress between 0 and 1', () {
      final overfunded = SavingsGoal.fromJson({
        'id': 'goal-5',
        'name': 'Overfunded',
        'targetAmount': '100.00',
        'currentAmount': '150.00',
      });
      final negative = SavingsGoal.fromJson({
        'id': 'goal-6',
        'name': 'Negative',
        'targetAmount': '100.00',
        'currentAmount': '-50.00',
      });

      expect(overfunded.progress, 1.0);
      expect(negative.progress, 0.0);
    });

    test('progress is 0 when targetAmount is 0', () {
      final goal = SavingsGoal.fromJson({
        'id': 'goal-7',
        'name': 'Zero target',
        'targetAmount': '0.00',
        'currentAmount': '500.00',
      });

      expect(goal.progress, 0.0);
    });
  });
}
