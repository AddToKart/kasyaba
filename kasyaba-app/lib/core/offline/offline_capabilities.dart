/// Every user action whose offline behaviour is part of the product contract.
///
/// Queueable actions are captured locally and replayed when connectivity
/// returns. Everything else is online-only and must be explicitly gated in the
/// UI with a "needs internet" reason instead of failing at the server.
enum OfflineAction {
  addExpense,
  addIncome,
  addTransfer,
  goalDeposit,
  markBillPaid,
  markBillUnpaid,
  cancelBill,
  createBill,
  createBudget,
  deleteBudget,
  createAccount,
  archiveAccount,
  updateProfile,
  createGoal,
  updateGoal,
  deleteGoal,
  evaluatePurchase,
  exportBackup,
  restoreBackup,
  deleteAccount,
}

class OfflineCapabilities {
  OfflineCapabilities._();

  static bool isQueueable(OfflineAction action) => switch (action) {
    OfflineAction.addExpense ||
    OfflineAction.addIncome ||
    OfflineAction.addTransfer ||
    OfflineAction.goalDeposit => true,
    _ => false,
  };
}
