import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/widgets/state_views.dart';

void main() {
  testWidgets('EmptyStateView renders icon and message', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EmptyStateView(icon: Icons.school_outlined, message: 'No courses yet')),
    ));
    expect(find.text('No courses yet'), findsOneWidget);
  });

  testWidgets('ErrorStateView retry fires', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ErrorStateView(message: 'Could not load courses', onRetry: () => retried = true)),
    ));
    await tester.tap(find.text('Try again'));
    expect(retried, true);
  });
}
