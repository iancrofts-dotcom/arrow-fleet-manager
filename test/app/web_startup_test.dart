import 'dart:async';

import 'package:arrow_fleet_manager/app/web_startup.dart';
import 'package:arrow_fleet_manager/shared/widgets/fleetiq_brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders a safe branded frame while Web bootstrap is pending', (
    tester,
  ) async {
    final initialization = Completer<void>();

    await tester.pumpWidget(
      WebStartup(
        initialize: () => initialization.future,
        application: const MaterialApp(home: Text('Protected application')),
      ),
    );

    expect(find.byType(FleetIqBrand), findsOneWidget);
    expect(find.text('SMARTER FLEET MANAGEMENT'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Protected application'), findsNothing);

    initialization.complete();
    await tester.pump();

    expect(find.text('Protected application'), findsOneWidget);
  });

  testWidgets('startup failure remains safe and can retry', (tester) async {
    final retry = Completer<void>();
    var attempts = 0;

    await tester.pumpWidget(
      WebStartup(
        initialize: () {
          attempts++;
          return attempts == 1
              ? Future<void>.error(StateError('private'))
              : retry.future;
        },
        application: const MaterialApp(home: Text('Protected application')),
      ),
    );
    await tester.pump();

    expect(
      find.text(
        'FleetIQ could not start. Check your connection and try again.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('private'), findsNothing);

    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Protected application'), findsNothing);

    retry.complete();
    await tester.pump();
    expect(find.text('Protected application'), findsOneWidget);
  });
}
