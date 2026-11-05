import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/offline/offline_capabilities.dart';

void main() {
  test('queueable actions match the offline contract (D3)', () {
    const queueable = {
      OfflineAction.addExpense,
      OfflineAction.addIncome,
      OfflineAction.addTransfer,
      OfflineAction.goalDeposit,
    };

    for (final action in OfflineAction.values) {
      expect(
        OfflineCapabilities.isQueueable(action),
        queueable.contains(action),
        reason: '$action must ${queueable.contains(action) ? '' : 'not '}be queueable',
      );
    }
  });

  test('online-only actions are explicitly not queueable', () {
    const onlineOnly = [
      OfflineAction.markBillPaid,
      OfflineAction.markBillUnpaid,
      OfflineAction.cancelBill,
      OfflineAction.createBill,
      OfflineAction.createBudget,
      OfflineAction.deleteBudget,
      OfflineAction.createAccount,
      OfflineAction.archiveAccount,
      OfflineAction.updateProfile,
      OfflineAction.createGoal,
      OfflineAction.updateGoal,
      OfflineAction.deleteGoal,
      OfflineAction.evaluatePurchase,
      OfflineAction.exportBackup,
      OfflineAction.restoreBackup,
      OfflineAction.deleteAccount,
    ];

    for (final action in onlineOnly) {
      expect(OfflineCapabilities.isQueueable(action), isFalse);
    }
  });
}
