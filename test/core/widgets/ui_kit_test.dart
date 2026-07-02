import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/widgets/pill_button.dart';
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
  });
}
