import 'package:arrow_fleet_manager/features/dashboard/widgets/quick_action_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('QuickActionCard invokes its supplied action', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickActionCard(
            icon: Icons.add_circle_outline,
            title: 'Add vehicle',
            subtitle: 'Register a vehicle',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Add vehicle'));

    expect(tapped, isTrue);
  });
}
