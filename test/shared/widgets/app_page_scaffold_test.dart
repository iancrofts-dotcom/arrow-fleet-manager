import 'package:arrow_fleet_manager/shared/status_badge.dart';
import 'package:arrow_fleet_manager/shared/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppPageScaffold renders its header, action, and body', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AppPageScaffold(
          title: 'Fleet Vehicles',
          subtitle: 'Operational fleet overview.',
          actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add))],
          child: const Center(child: Text('Page body')),
        ),
      ),
    );

    expect(find.text('Arrow Fleet Manager'), findsOneWidget);
    expect(find.text('Fleet Vehicles'), findsOneWidget);
    expect(find.text('Page body'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('AppPageScaffold uses a supplied custom header', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AppPageScaffold(
          title: 'Hidden default title',
          customHeader: Text('Dashboard custom header'),
          child: Center(child: Text('Custom header body')),
        ),
      ),
    );

    expect(find.text('Dashboard custom header'), findsOneWidget);
    expect(find.text('Custom header body'), findsOneWidget);
    expect(find.text('Hidden default title'), findsNothing);
  });

  testWidgets('shared states render configured text and retry action', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            title: 'Unable to load vehicles',
            message: 'Try again shortly.',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Unable to load vehicles'), findsOneWidget);
    expect(find.text('Try again shortly.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, isTrue);
  });

  testWidgets('StatusBadge always includes its text label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: StatusBadge.neutral('Not Recorded'))),
    );

    expect(find.text('Not Recorded'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
