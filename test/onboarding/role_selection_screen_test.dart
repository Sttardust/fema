import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/onboarding/presentation/role_selection_screen.dart';

void main() {
  testWidgets('role picker shows only Student and Teacher', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RoleSelectionScreen()),
      ),
    );

    expect(find.text('I am a Student'), findsOneWidget);
    expect(find.text('I am a Teacher'), findsOneWidget);
    expect(find.text('I am a Parent'), findsNothing);
    expect(find.text('I am an Educator/Admin'), findsNothing);
  });
}
