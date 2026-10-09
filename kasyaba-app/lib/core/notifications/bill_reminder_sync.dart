import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_providers.dart';
import 'notification_service.dart';

/// Keeps local bill reminders in step with the current bill list. Watched by
/// the app root so it stays active for the whole session.
final billReminderSyncProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<List<BillItem>>>(billsProvider, (_, next) {
    final bills = next.valueOrNull;
    if (bills == null) return;
    unawaited(
      NotificationService.instance.syncBillReminders(
        bills.map(
          (bill) => BillReminder(
            id: bill.id,
            name: bill.name,
            dueDate: bill.dueDate,
            status: bill.status,
          ),
        ),
      ),
    );
  }, fireImmediately: true);
});
