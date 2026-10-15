import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/features/splash/screens/splash_screen.dart';
import 'package:kasyaba/shared/widgets/empty_state_view.dart';

void main() {
  testWidgets('splash screen shows the brand and a loader', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SplashScreen()));

    expect(find.text('KASYABA'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty state renders its copy and fires the action', (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyStateView(
            title: 'No transactions yet',
            message: 'Add your first income or expense to get started.',
            icon: Icons.receipt_long_outlined,
            actionLabel: 'Add transaction',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No transactions yet'), findsOneWidget);
    expect(find.text('Add your first income or expense to get started.'), findsOneWidget);

    await tester.tap(find.text('Add transaction'));
    expect(tapped, isTrue);
  });
}
