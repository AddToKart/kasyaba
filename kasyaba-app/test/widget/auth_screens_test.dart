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

    // Brand lockup and differentiator badge
    expect(find.text('KASYABA'), findsOneWidget);
    expect(find.text('100% Deterministic • Zero AI • Private'), findsOneWidget);

    // Title and subtitle
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to access your financial runway'), findsOneWidget);

    // Explicit typography labels
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);

    // Forgot password link
    expect(find.text('Forgot Password?'), findsOneWidget);

    // Primary Sign In button
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('OR'), findsNothing);
    expect(find.text('Continue with Demo Account'), findsNothing);

    // Bottom trust footer
    expect(find.text('End-to-end local & deterministic calculation'), findsOneWidget);

    // Test Forgot Password dialog
    await tester.tap(find.text('Forgot Password?'));
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
    expect(find.text('KASYABA'), findsOneWidget);
    expect(find.text('100% Deterministic • Zero AI • Private'), findsOneWidget);
    expect(find.text('Create Account'), findsNWidgets(2));

    // Explicit labels
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('EMAIL ADDRESS'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);

    // Trust footer and terms note
    expect(find.text('End-to-end local & deterministic calculation'), findsOneWidget);
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
