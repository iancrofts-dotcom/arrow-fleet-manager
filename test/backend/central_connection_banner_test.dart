import 'package:arrow_fleet_manager/backend/resilience/central_connection_tracker.dart';
import 'package:arrow_fleet_manager/backend/resilience/central_failure_kind.dart';
import 'package:arrow_fleet_manager/shared/widgets/central_connection_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'connection boundary is silent while status is unknown or online',
    (tester) async {
      final tracker = CentralConnectionTracker();
      await tester.pumpWidget(
        MaterialApp(
          home: CentralConnectionBoundary(
            tracker: tracker,
            child: const Scaffold(body: Text('FleetIQ content')),
          ),
        ),
      );

      expect(find.text('FleetIQ content'), findsOneWidget);
      expect(find.textContaining('You’re offline'), findsNothing);

      tracker.recordSuccess();
      await tester.pump();
      expect(find.textContaining('You’re offline'), findsNothing);
    },
  );

  testWidgets(
    'network failure shows central unavailable without replacing content',
    (tester) async {
      final tracker = CentralConnectionTracker();
      await tester.pumpWidget(
        MaterialApp(
          home: CentralConnectionBoundary(
            tracker: tracker,
            child: const Scaffold(body: Text('FleetIQ content')),
          ),
        ),
      );

      tracker.recordFailure(CentralFailureKind.connectivity);
      await tester.pump();

      expect(find.text('FleetIQ content'), findsOneWidget);
      expect(find.textContaining('You’re offline'), findsOneWidget);
    },
  );

  testWidgets('permission failure shows degraded status rather than offline', (
    tester,
  ) async {
    final tracker = CentralConnectionTracker();
    await tester.pumpWidget(
      MaterialApp(
        home: CentralConnectionBoundary(
          tracker: tracker,
          child: const Scaffold(body: Text('FleetIQ content')),
        ),
      ),
    );

    tracker.recordFailure(CentralFailureKind.authorization);
    await tester.pump();

    expect(find.text('Central permission problem'), findsOneWidget);
    expect(find.textContaining('You’re offline'), findsNothing);
  });
}
