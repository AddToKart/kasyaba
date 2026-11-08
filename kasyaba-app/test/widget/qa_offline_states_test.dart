import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/connectivity/connectivity_service.dart';
import 'package:kasyaba/core/providers/api_providers.dart';
import 'package:kasyaba/features/bills/screens/bills_screen.dart';
import 'package:kasyaba/features/budgets/screens/budgets_screen.dart';
import 'package:kasyaba/features/planning/screens/planning_screen.dart';
import 'package:kasyaba/features/settings/screens/backup_export_screen.dart';
import 'package:kasyaba/features/settings/screens/delete_account_screen.dart';
import 'package:kasyaba/shared/widgets/offline_status.dart';
import 'package:kasyaba/shared/widgets/pill_button.dart';

import 'support/qa_harness.dart';

void main() {
  group('OfflineStatusBadge', () {
    testWidgets('renders nothing while online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [isOnlineProvider.overrideWithValue(true)],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineStatusBadge(snapshotKey: 'dashboard'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline'), findsNothing);
    });

    testWidgets('shows the cache age while offline', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isOnlineProvider.overrideWithValue(false),
            cachedSnapshotMetaProvider.overrideWith(
              (ref, key) async =>
                  DateTime.now().subtract(const Duration(hours: 2)),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: OfflineStatusBadge(snapshotKey: 'dashboard'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline'), findsOneWidget);
      expect(find.textContaining('2h ago'), findsOneWidget);
    });
  });

  final harness = QaHarness();

  testWidgets('bills screen explains online-only actions while offline',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const BillsScreen(),
      overrides: [
        ...qaDefaultDataOverrides(),
        isOnlineProvider.overrideWithValue(false),
        // Cold-start offline without a cached snapshot: providers fail and the
        // screen must explain that a connection is required.
        billsProvider.overrideWith((ref) async => throw Exception('offline')),
      ],
    );

    expect(find.byType(NeedsInternetNotice), findsWidgets);
  });

  testWidgets('budgets screen explains online-only actions while offline',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const BudgetsScreen(),
      overrides: [
        ...qaDefaultDataOverrides(),
        isOnlineProvider.overrideWithValue(false),
      ],
    );

    expect(find.byType(NeedsInternetNotice), findsWidgets);
  });

  testWidgets('planning screen shows the connection notice instead of a '
      'generic error while offline', (tester) async {
    await harness.pumpScreen(
      tester,
      const PlanningScreen(),
      overrides: [
        ...qaDefaultDataOverrides(),
        isOnlineProvider.overrideWithValue(false),
      ],
    );

    expect(find.byType(NeedsInternetNotice), findsWidgets);
    expect(find.textContaining('connection'), findsWidgets);
  });

  testWidgets('backup export disables its actions while offline',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const BackupExportScreen(),
      overrides: [isOnlineProvider.overrideWithValue(false)],
    );

    expect(find.byType(NeedsInternetNotice), findsWidgets);

    final buttons = tester
        .widgetList<PillButton>(find.byType(PillButton))
        .toList(growable: false);
    expect(buttons, isNotEmpty,
        reason: 'backup screen should render its action pills');
    expect(
      buttons.every((button) => button.onPressed == null),
      isTrue,
      reason: 'every backup action is online-only and must be disabled '
          'while offline',
    );
  });

  testWidgets('delete account is gated while offline', (tester) async {
    await harness.pumpScreen(
      tester,
      const DeleteAccountScreen(),
      overrides: [isOnlineProvider.overrideWithValue(false)],
    );

    expect(find.byType(NeedsInternetNotice), findsWidgets);

    final deleteButton = tester.widget<PillButton>(
      find.widgetWithText(PillButton, 'Delete account and data'),
    );
    expect(
      deleteButton.onPressed,
      isNull,
      reason: 'account deletion is online-only and must be disabled offline',
    );
  });

  testWidgets('delete account shows no offline notice while online',
      (tester) async {
    await harness.pumpScreen(
      tester,
      const DeleteAccountScreen(),
      overrides: [isOnlineProvider.overrideWithValue(true)],
    );

    expect(find.byType(NeedsInternetNotice), findsNothing);
  });
}
