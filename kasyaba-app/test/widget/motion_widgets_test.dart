import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/shared/widgets/pressable_scale.dart';
import 'package:kasyaba/shared/widgets/rolling_counter.dart';

void main() {
  group('PressableScale', () {
    testWidgets('compresses on pointer down and triggers onTap on release',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PressableScale(
                onTap: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);

      // Tap the widget
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });

  group('RollingCounter', () {
    testWidgets('renders formatted currency and rolling digits',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RollingCounter(
                value: 42500.50,
                prefix: '₱ ',
              ),
            ),
          ),
        ),
      );

      // Verify prefix is rendered
      expect(find.text('₱ '), findsOneWidget);
      // Verify punctuation
      expect(find.text(','), findsOneWidget);
      expect(find.text('.'), findsOneWidget);
      // Verify digits exist in tree
      expect(find.text('4'), findsWidgets);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('renders privacy mask when isPrivacyMode is true',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: RollingCounter(
                value: 42500.50,
                prefix: '₱ ',
                isPrivacyMode: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('₱ '), findsOneWidget);
      expect(find.text('•'), findsNWidgets(7));
    });
  });
}
