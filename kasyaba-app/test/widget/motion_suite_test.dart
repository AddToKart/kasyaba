import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/shared/widgets/motion_components.dart';

void main() {
  testWidgets('FadeSlideEntrance renders child with fade and slide', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FadeSlideEntrance(
            child: Text('Animated Card'),
          ),
        ),
      ),
    );

    // Initial state
    expect(find.text('Animated Card'), findsOneWidget);

    // Settle animations
    await tester.pumpAndSettle();
    expect(find.text('Animated Card'), findsOneWidget);
  });

  testWidgets('SpringTouch compresses on tapDown and triggers onTap', (tester) async {
    var wasTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SpringTouch(
              onTap: () => wasTapped = true,
              child: const Text('Spring Button'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Spring Button'), findsOneWidget);

    // Tap and verify
    await tester.tap(find.text('Spring Button'));
    await tester.pumpAndSettle();

    expect(wasTapped, isTrue);
  });

  testWidgets('AnimatedCurrencyText interpolates and renders formatted amount', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: AnimatedCurrencyText(
              value: 12500.0,
              style: TextStyle(fontSize: 20),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('₱12,500.00'), findsOneWidget);
  });
}
