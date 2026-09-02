import 'package:arrow_fleet_manager/features/inspections/widgets/inspection_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('walkaround metadata remains readable at mobile width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const inspectionNumber = 'AST-2026-1788348832068921-000002';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InspectionHeader(
            inspectionNumber: inspectionNumber,
            inspectionDate: DateTime(2026, 9, 2, 12, 33),
          ),
        ),
      ),
    );

    expect(find.text('Inspection Number'), findsOneWidget);
    expect(find.text(inspectionNumber), findsOneWidget);
    expect(find.text('Inspection Date'), findsOneWidget);
    expect(find.text('Inspection Time'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Daily Walkaround Inspection'), findsOneWidget);
    expect(find.text('Arrow Fleet Manager'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
