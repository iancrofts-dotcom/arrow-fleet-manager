import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_inspection.dart';
import 'package:arrow_fleet_manager/backend/workshop/backend_workshop_repair_job.dart';
import 'package:arrow_fleet_manager/backend/workshop/central_workshop_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central Workshop summary counts operational status', () {
    final summary = CentralWorkshopSummary.fromData(
      inspections: [
        _inspection(status: 'draft', criticalFailures: 0),
        _inspection(status: 'awaitingRepair', criticalFailures: 2),
        _inspection(status: 'signedOff', criticalFailures: 0),
      ],
      repairJobs: [
        _repair(status: 'open', partsRequired: true),
        _repair(status: 'inProgress', partsRequired: false),
        _repair(status: 'completed', partsRequired: true),
      ],
    );

    expect(summary.totalInspections, 3);
    expect(summary.openInspections, 2);
    expect(summary.completedInspections, 1);
    expect(summary.criticalFailures, 2);
    expect(summary.outstandingRepairs, 2);
    expect(summary.awaitingParts, 1);
  });
}

BackendWorkshopInspection _inspection({
  required String status,
  required int criticalFailures,
}) => BackendWorkshopInspection(
  id: 'inspection-$status',
  inspectionNumber: 'WI-$status',
  vehicleId: 'vehicle-1',
  registration: 'TEST123',
  fleetNumber: 'F1',
  technicianName: 'Tech',
  inspectionType: 'annualInspection',
  status: status,
  vehicleStatus: 'roadworthy',
  dateStarted: DateTime.utc(2026, 9, 9),
  mileage: 100,
  overallResult: 'pass',
  inspectionScore: 100,
  criticalFailures: criticalFailures,
  advisories: 0,
  repairsRequired: 0,
  labourHours: 0,
  totalCost: 0,
  notes: '',
  createdAt: DateTime.utc(2026, 9, 9),
  updatedAt: DateTime.utc(2026, 9, 9),
);

BackendWorkshopRepairJob _repair({
  required String status,
  required bool partsRequired,
}) => BackendWorkshopRepairJob(
  id: 'repair-$status',
  jobNumber: 'RJ-$status',
  inspectionId: 'inspection-1',
  vehicleId: 'vehicle-1',
  vehicleRegistration: 'TEST123',
  title: 'Repair',
  description: '',
  priority: 'medium',
  status: status,
  technicianName: 'Tech',
  partsRequired: partsRequired,
  estimatedHours: 0,
  actualHours: 0,
  estimatedCost: 0,
  actualCost: 0,
  roadworthy: false,
  createdAt: DateTime.utc(2026, 9, 9),
);
