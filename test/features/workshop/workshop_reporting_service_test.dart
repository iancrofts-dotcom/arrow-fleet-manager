import 'package:arrow_fleet_manager/features/workshop/models/inspection_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/repair_job.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:arrow_fleet_manager/features/workshop/services/workshop_reporting_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = WorkshopReportingService();
  group('WorkshopReportingService', () {
    test('uses inclusive local date ranges and persisted repair filters', () {
      final jobs = [
        _job('RJ-1', createdAt: DateTime(2026, 8, 19, 23, 59), technicianId: 'tech-1'),
        _job('RJ-2', createdAt: DateTime(2026, 8, 12), technicianId: 'tech-1'),
        _job('RJ-3', createdAt: DateTime(2026, 8, 11, 23, 59), technicianId: 'tech-2'),
      ];
      final filtered = service.filterJobs(jobs, WorkshopReportFilter(start: DateTime(2026, 8, 12), end: DateTime(2026, 8, 19), technicianId: 'tech-1'));
      expect(filtered.map((job) => job.jobNumber), ['RJ-1', 'RJ-2']);
    });

    test('filters technicians by authoritative ID, never by matching name', () {
      final jobs = [
        _job('RJ-1', technicianId: 'technician-a', technicianName: 'Alex'),
        _job('RJ-2', technicianId: null, technicianName: 'Alex'),
        _job('RJ-3', technicianId: 'technician-b', technicianName: 'Alex'),
      ];
      final filtered = service.filterJobs(jobs, WorkshopReportFilter(technicianId: 'technician-a'));
      expect(filtered.single.jobNumber, 'RJ-1');
    });

    test('applies vehicle, status and priority filters together', () {
      final jobs = [
        _job('RJ-1', status: RepairJobStatus.awaitingInspection)
            .copyWith(priority: RepairPriority.high),
        _job('RJ-2').copyWith(
          vehicleId: 2,
          priority: RepairPriority.high,
          status: RepairJobStatus.awaitingInspection,
        ),
        _job('RJ-3').copyWith(priority: RepairPriority.low),
      ];
      final filtered = service.filterJobs(
        jobs,
        WorkshopReportFilter(
          vehicleId: 1,
          status: RepairJobStatus.awaitingInspection,
          priority: RepairPriority.high,
        ),
      );
      expect(filtered.single.jobNumber, 'RJ-1');
    });

    test('rejects an invalid custom range', () {
      expect(
        () => WorkshopReportFilter(
          start: DateTime(2026, 8, 20),
          end: DateTime(2026, 8, 19),
        ),
        throwsAssertionError,
      );
    });

    test('summarises vehicle repair state from saved inspection snapshots', () {
      final inspection = _inspection();
      final history = service.vehicleHistory(
        vehicleId: 1,
        inspections: [inspection],
        jobs: [
          _job('RJ-1', status: RepairJobStatus.completed, actualHours: 2, actualCost: 30),
          _job('RJ-2', status: RepairJobStatus.awaitingParts, actualHours: 1, actualCost: 10),
        ],
        itemsByInspection: {
          1: [
            InspectionItem(inspectionId: 1, category: InspectionCategory.brakes, title: 'Brake wear', status: InspectionItemStatus.fail, repairRequired: true, displayOrder: 1),
            InspectionItem(inspectionId: 1, category: InspectionCategory.brakes, title: 'Lights', status: InspectionItemStatus.pass, displayOrder: 2),
          ],
        },
      );
      expect(history.failedOrRepairRequiredItems, 1);
      expect(history.completedJobs, 1);
      expect(history.outstandingJobs, 1);
      expect(history.actualHours, 3);
      expect(history.actualCost, 40);
    });

    test('keeps cancelled work out of outstanding cost totals', () {
      final summary = service.costSummary([
        _job('RJ-1', status: RepairJobStatus.completed, actualCost: 50),
        _job('RJ-2', status: RepairJobStatus.inProgress, actualCost: 10),
        _job('RJ-3', status: RepairJobStatus.cancelled, actualCost: 20),
      ]);
      expect(summary.completedJobs, 1);
      expect(summary.outstandingJobs, 1);
      expect(summary.actualCost, 80);
    });

    test('summarises only the selected technician account', () {
      final summary = service.technicianSummary([
        _job('RJ-1', technicianId: 'tech-a', status: RepairJobStatus.assigned, actualHours: 2, actualCost: 20),
        _job('RJ-2', technicianId: 'tech-a', status: RepairJobStatus.completed, actualHours: 3, actualCost: 30),
        _job('RJ-3', technicianId: 'tech-b', status: RepairJobStatus.completed),
      ], 'tech-a');
      expect(summary.jobs.length, 2);
      expect(summary.activeJobs, 1);
      expect(summary.completedJobs, 1);
      expect(summary.actualHours, 5);
      expect(summary.actualCost, 50);
    });
  });
}

RepairJob _job(
  String number, {
  DateTime? createdAt,
  String? technicianId,
  String technicianName = '',
  RepairJobStatus status = RepairJobStatus.open,
  double actualHours = 0,
  double actualCost = 0,
}) => RepairJob(
  jobNumber: number,
  inspectionId: 1,
  inspectionItemId: 1,
  vehicleId: 1,
  vehicleRegistration: 'AB12 CDE',
  title: 'Repair',
  description: 'Saved work detail',
  technicianId: technicianId,
  technicianName: technicianName,
  status: status,
  actualHours: actualHours,
  actualCost: actualCost,
  createdAt: createdAt ?? DateTime(2026, 8, 19),
);

WorkshopInspection _inspection() => WorkshopInspection(
  id: 1,
  inspectionNumber: 'WI-1',
  vehicleId: 1,
  registration: 'AB12 CDE',
  fleetNumber: 'F-1',
  technicianName: '',
  inspectionType: WorkshopInspectionType.defectInspection,
  status: WorkshopInspectionStatus.awaitingRepair,
  vehicleStatus: VehicleWorkshopStatus.awaitingRepair,
  dateStarted: DateTime(2026, 8, 19),
  mileage: 1000,
  overallResult: InspectionResult.fail,
  inspectionScore: 0,
  criticalFailures: 1,
  advisories: 0,
  repairsRequired: 1,
  labourHours: 0,
  totalCost: 0,
  notes: '',
  createdAt: DateTime(2026, 8, 19),
  updatedAt: DateTime(2026, 8, 19),
);
