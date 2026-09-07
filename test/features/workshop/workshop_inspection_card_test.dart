import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:arrow_fleet_manager/features/workshop/widgets/workshop_inspection_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'renders an awaiting-repair Driver Daily inspection at phone width',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WorkshopInspectionCard(
              inspection: _inspection(
                inspectionType: WorkshopInspectionType.driverDailyInspection,
                status: WorkshopInspectionStatus.awaitingRepair,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Driver Daily Walkaround Check'), findsOneWidget);
      expect(find.text('Awaiting Repair'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

WorkshopInspection _inspection({
  required WorkshopInspectionType inspectionType,
  required WorkshopInspectionStatus status,
}) {
  final now = DateTime(2026, 9, 7, 9, 30);
  return WorkshopInspection(
    id: 1,
    inspectionNumber: 'INSP-0001',
    vehicleId: 1,
    registration: 'AB12 CDE',
    fleetNumber: 'FLEET-1',
    technicianName: 'Workshop Team',
    driverId: 2,
    driverName: 'A very long driver name for narrow phone layouts',
    inspectionType: inspectionType,
    status: status,
    vehicleStatus: VehicleWorkshopStatus.awaitingRepair,
    dateStarted: now,
    mileage: 12000,
    overallResult: InspectionResult.fail,
    inspectionScore: 80,
    criticalFailures: 0,
    advisories: 1,
    repairsRequired: 2,
    labourHours: 0,
    totalCost: 0,
    notes: '',
    createdAt: now,
    updatedAt: now,
  );
}
