import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasyaba/features/auth/screens/login_screen.dart';
import 'package:kasyaba/features/auth/screens/register_screen.dart';
import 'package:kasyaba/features/auth/screens/forgot_password_screen.dart';
import 'package:kasyaba/features/auth/widgets/auth_widgets.dart';

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
    await tester.ensureVisible(find.text('Forgot password?'));
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

  testWidgets('RegisterScreen renders exact Figma elements, form card, and continue button',
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

    // No onboarding step copy (single-step registration)
    expect(find.text('STEP 1 OF 2'), findsNothing);

    // Screen Title and Subtitle
    expect(find.text('Create your account.'), findsOneWidget);
    expect(find.text('Takes a minute. Then we tailor Kasyaba to you.'), findsOneWidget);

    // Explicit field labels
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('EMAIL'), findsOneWidget);
    expect(find.text('PASSWORD'), findsOneWidget);
    expect(find.text('CONFIRM PASSWORD'), findsOneWidget);

    // Primary Continue button
    expect(find.text('Continue'), findsOneWidget);

    // Trust footer
    expect(find.text('Calculated on your device. Your numbers stay yours.'), findsOneWidget);

    // Fill form and check validity
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(4));
    await tester.enterText(fields.at(0), 'Juan Dela Cruz');
    await tester.enterText(fields.at(1), 'juan@example.com');
    await tester.enterText(fields.at(2), 'Password123!');
    await tester.enterText(fields.at(3), 'Password123!');
    await tester.pump();

    // Password strength and match indicators are wired to the form
    expect(find.text('Strong password'), findsOneWidget);
    expect(find.text('Passwords match'), findsOneWidget);

    // Terms & Conditions checkbox rendered
    expect(find.text('Terms & Conditions'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);

    // Tapping Continue without checking triggers validation message
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('You must accept the Terms & Conditions to proceed'),
      findsOneWidget,
    );

    // Tapping the checkbox clears the validation error
    await tester.tap(find.descendant(
      of: find.byType(AuthTermsCheckbox),
      matching: find.byType(AnimatedContainer),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.text('You must accept the Terms & Conditions to proceed'),
      findsNothing,
    );
  });

  testWidgets('ForgotPasswordScreen renders exact Figma elements, back button, inline field, and action button',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Title and Subtitle
    expect(find.text('Reset your password'), findsOneWidget);
    expect(find.textContaining('Enter the email you signed up with'), findsOneWidget);

    // Inline capsule email field and label
    expect(find.text('Email'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Sign in link
    expect(find.text('Remembered it? '), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    // Primary Action Button
    expect(find.text('Send reset link'), findsOneWidget);
  });
}
