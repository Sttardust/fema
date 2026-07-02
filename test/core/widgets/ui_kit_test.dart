import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/widgets/pill_button.dart';
import 'package:fema/core/widgets/pill_text_field.dart';
import 'package:fema/core/widgets/soft_card.dart';
import 'package:fema/core/widgets/capsule_tab_bar.dart';

void main() {
  testWidgets('ui kit renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          PillButton(label: 'Continue', onPressed: () {}),
          PillButton.outlined(label: 'Browse as guest', onPressed: () {}),
          const SoftCard(child: Text('card')),
          const PillTextField(hint: 'Email address', icon: Icons.mail_outline),
        ]),
        bottomNavigationBar: CapsuleTabBar(
          currentIndex: 0,
          onTap: (_) {},
          items: const [
            CapsuleTabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
            CapsuleTabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
          ],
        ),
      ),
    ));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('card'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Email address'), findsOneWidget);
  });

  testWidgets('SoftCard onTap covers padded area', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SoftCard(
          padding: const EdgeInsets.all(32),
          onTap: () => tapped = true,
          child: const SizedBox(width: 10, height: 10),
        ),
      ),
    ));
    // Tap in the padding zone (left-center), well clear of the child and the rounded corners.
    final rect = tester.getRect(find.byType(SoftCard));
    await tester.tapAt(rect.centerLeft + const Offset(5, 0));
    expect(tapped, true);
  });
}
