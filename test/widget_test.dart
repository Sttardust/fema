import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/auth/presentation/welcome_screen.dart';

void main() {
  testWidgets('welcome screen renders primary actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    expect(find.text('Welcome to FEMA'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
