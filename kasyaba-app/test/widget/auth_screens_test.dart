import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/features/auth/screens/login_screen.dart';
import 'package:kasyaba/features/auth/screens/register_screen.dart';

void main() {
  testWidgets('LoginScreen renders brand lockup, explicit labels, demo button, and trust footer',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Brand lockup and runway badge
    expect(find.text('Kasyaba'), findsOneWidget);
    expect(find.text('Can I afford it?'), findsOneWidget);

    // Title and subtitle
    expect(find.text('Welcome back.'), findsOneWidget);
    expect(find.text('Pick up where your runway left off.'), findsOneWidget);

    // Explicit typography labels
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);

    // Forgot password link
    expect(find.text('Forgot password?'), findsOneWidget);

    // Primary Sign in button
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('OR'), findsNothing);
    expect(find.text('Continue with Demo Account'), findsNothing);

    // Bottom reassurance footnote
    expect(find.text('Calculated on your device. Your numbers stay yours.'), findsOneWidget);

    // Test Forgot Password dialog
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.text('Understood'), findsOneWidget);

    await tester.tap(find.text('Understood'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Reset Password'), findsNothing);
  });

  testWidgets('RegisterScreen renders brand lockup, password strength, and match indicator',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Brand lockup and header
    expect(find.text('Kasyaba'), findsOneWidget);
    expect(find.text('Create Account'), findsNWidgets(2));

    // Explicit labels
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);

    // Trust footer and terms note
    expect(find.text('Calculated on your device. Your numbers stay yours.'), findsOneWidget);
    expect(find.textContaining('Terms of Service and Privacy Policy'), findsOneWidget);

    // Enter a password to trigger strength indicator
    final passwordFields = find.byType(TextField);
    // passwordFields: [0: name, 1: email, 2: password, 3: confirmPassword]
    await tester.enterText(passwordFields.at(2), 'Pass123!@#');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('password'), findsWidgets);

    // Enter matching confirm password
    await tester.enterText(passwordFields.at(3), 'Pass123!@#');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Passwords match'), findsOneWidget);
  });
}
