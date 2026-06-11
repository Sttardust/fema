import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/onboarding/presentation/fema_intro_screen.dart';

void main() {
  testWidgets('intro carousel renders title and primary actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: FemaIntroScreen()),
    );

    expect(find.text('Welcome to FEMA!'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Browse the app'), findsOneWidget);
  });
}
