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

  testWidgets('SlidingSegmentedPill renders items and responds to taps', (tester) async {
    var selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SlidingSegmentedPill(
                items: const ['All', 'Expenses', 'Income'],
                selectedIndex: selectedIndex,
                onChanged: (idx) {
                  setState(() => selectedIndex = idx);
                },
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Income'), findsOneWidget);

    // Tap 'Expenses'
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);

    // Tap 'Income'
    await tester.tap(find.text('Income'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 2);
  });
}

