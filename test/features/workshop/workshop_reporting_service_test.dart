import 'package:arrow_fleet_manager/features/workshop/models/inspection_item.dart';
import 'package:arrow_fleet_manager/features/workshop/models/repair_job.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/workshop_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/services/workshop_reporting_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = WorkshopReportingService();
  group('WorkshopReportingService', () {
    test('uses inclusive local date ranges and persisted repair filters', () {
      final jobs = [
        _job(
          'RJ-1',
          createdAt: DateTime(2026, 8, 19, 23, 59),
          technicianId: 'tech-1',
        ),
        _job('RJ-2', createdAt: DateTime(2026, 8, 12), technicianId: 'tech-1'),
        _job(
          'RJ-3',
          createdAt: DateTime(2026, 8, 11, 23, 59),
          technicianId: 'tech-2',
        ),
      ];
      final filtered = service.filterJobs(
        jobs,
        WorkshopReportFilter(
          start: DateTime(2026, 8, 12),
          end: DateTime(2026, 8, 19),
          technicianId: 'tech-1',
        ),
      );
      expect(filtered.map((job) => job.jobNumber), ['RJ-1', 'RJ-2']);
    });

    test('filters technicians by authoritative ID, never by matching name', () {
      final jobs = [
        _job('RJ-1', technicianId: 'technician-a', technicianName: 'Alex'),
        _job('RJ-2', technicianId: null, technicianName: 'Alex'),
        _job('RJ-3', technicianId: 'technician-b', technicianName: 'Alex'),
      ];
      final filtered = service.filterJobs(
        jobs,
        WorkshopReportFilter(technicianId: 'technician-a'),
      );
      expect(filtered.single.jobNumber, 'RJ-1');
    });

    test('applies vehicle, status and priority filters together', () {
      final jobs = [
        _job(
          'RJ-1',
          status: RepairJobStatus.awaitingInspection,
        ).copyWith(priority: RepairPriority.high),
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

    test('vehicle history scope ignores hidden repair job filters', () {
      final filter = WorkshopReportFilter.scoped(
        scope: WorkshopReportFilterScope.vehicleHistory,
        start: DateTime(2026, 8, 19),
        end: DateTime(2026, 8, 19),
        vehicleId: 1,
        technicianId: 'tech-a',
        status: RepairJobStatus.completed,
        priority: RepairPriority.high,
      );

      final filtered = service.filterJobs([
        _job('RJ-1', technicianId: 'tech-b'),
        _job('RJ-2', technicianId: 'tech-a').copyWith(vehicleId: 2),
      ], filter);

      expect(filtered.map((job) => job.jobNumber), ['RJ-1']);
      expect(filter.technicianId, isNull);
      expect(filter.status, isNull);
      expect(filter.priority, isNull);
    });

    test(
      'technician work scope ignores hidden vehicle status and priority',
      () {
        final filter = WorkshopReportFilter.scoped(
          scope: WorkshopReportFilterScope.technicianWork,
          start: DateTime(2026, 8, 19),
          end: DateTime(2026, 8, 19),
          vehicleId: 1,
          technicianId: 'tech-a',
          status: RepairJobStatus.completed,
          priority: RepairPriority.high,
        );

        final filtered = service.filterJobs([
          _job('RJ-1', technicianId: 'tech-a'),
          _job(
            'RJ-2',
            technicianId: 'tech-a',
          ).copyWith(vehicleId: 2, priority: RepairPriority.low),
          _job('RJ-3', technicianId: 'tech-b'),
        ], filter);

        expect(filtered.map((job) => job.jobNumber), ['RJ-1', 'RJ-2']);
        expect(filter.vehicleId, isNull);
        expect(filter.status, isNull);
        expect(filter.priority, isNull);
      },
    );

    test('repair job scope retains visible filters and date range', () {
      final start = DateTime(2026, 8, 19);
      final end = DateTime(2026, 8, 20);
      final filter = WorkshopReportFilter.scoped(
        scope: WorkshopReportFilterScope.repairJobs,
        start: start,
        end: end,
        vehicleId: 1,
        technicianId: 'tech-a',
        status: RepairJobStatus.open,
        priority: RepairPriority.medium,
      );

      expect(filter.start, start);
      expect(filter.end, end);
      expect(filter.vehicleId, 1);
      expect(filter.technicianId, 'tech-a');
      expect(filter.status, RepairJobStatus.open);
      expect(filter.priority, RepairPriority.medium);
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
          _job(
            'RJ-1',
            status: RepairJobStatus.completed,
            actualHours: 2,
            actualCost: 30,
          ),
          _job(
            'RJ-2',
            status: RepairJobStatus.awaitingParts,
            actualHours: 1,
            actualCost: 10,
          ),
        ],
        itemsByInspection: {
          1: [
            InspectionItem(
              inspectionId: 1,
              category: InspectionCategory.brakes,
              title: 'Brake wear',
              status: InspectionItemStatus.fail,
              repairRequired: true,
              displayOrder: 1,
            ),
            InspectionItem(
              inspectionId: 1,
              category: InspectionCategory.brakes,
              title: 'Lights',
              status: InspectionItemStatus.pass,
              displayOrder: 2,
            ),
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
        _job(
          'RJ-1',
          technicianId: 'tech-a',
          status: RepairJobStatus.assigned,
          actualHours: 2,
          actualCost: 20,
        ),
        _job(
          'RJ-2',
          technicianId: 'tech-a',
          status: RepairJobStatus.completed,
          actualHours: 3,
          actualCost: 30,
        ),
        _job('RJ-3', technicianId: 'tech-b', status: RepairJobStatus.completed),
      ], 'tech-a');
      expect(summary.jobs.length, 2);
      expect(summary.activeJobs, 1);
      expect(summary.completedJobs, 1);
      expect(summary.actualHours, 5);
      expect(summary.actualCost, 50);
    });

    test(
      'loads source inspections by ID for in-range repair jobs without applying inspection date filtering',
      () async {
        final inspection = _inspection(
          id: 42,
          dateStarted: DateTime(2026, 7, 1),
        );
        final repository = _InspectionContextRepository({42: inspection});
        final reporting = WorkshopReportingService(repository: repository);
        final jobs = reporting.filterJobs(
          [
            _job('RJ-1', inspectionId: 42, createdAt: DateTime(2026, 8, 20, 9)),
            _job(
              'RJ-2',
              inspectionId: 42,
              createdAt: DateTime(2026, 8, 20, 10),
            ),
          ],
          WorkshopReportFilter(
            start: DateTime(2026, 8, 20),
            end: DateTime(2026, 8, 20),
          ),
        );

        final contexts = await reporting.loadInspectionsForRepairJobs(jobs);

        expect(jobs, hasLength(2));
        expect(contexts, [inspection]);
        expect(repository.requestedIds, [42]);
      },
    );

    test('safely omits missing repair-job inspection references', () async {
      final repository = _InspectionContextRepository(const {});
      final reporting = WorkshopReportingService(repository: repository);

      final contexts = await reporting.loadInspectionsForRepairJobs([
        _job('RJ-missing', inspectionId: 404),
      ]);

      expect(contexts, isEmpty);
      expect(repository.requestedIds, [404]);
    });
  });
}

RepairJob _job(
  String number, {
  DateTime? createdAt,
  int inspectionId = 1,
  String? technicianId,
  String technicianName = '',
  RepairJobStatus status = RepairJobStatus.open,
  double actualHours = 0,
  double actualCost = 0,
}) => RepairJob(
  jobNumber: number,
  inspectionId: inspectionId,
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

WorkshopInspection _inspection({int id = 1, DateTime? dateStarted}) =>
    WorkshopInspection(
      id: id,
      inspectionNumber: 'WI-1',
      vehicleId: 1,
      registration: 'AB12 CDE',
      fleetNumber: 'F-1',
      technicianName: '',
      inspectionType: WorkshopInspectionType.defectInspection,
      status: WorkshopInspectionStatus.awaitingRepair,
      vehicleStatus: VehicleWorkshopStatus.awaitingRepair,
      dateStarted: dateStarted ?? DateTime(2026, 8, 19),
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

class _InspectionContextRepository extends WorkshopRepository {
  _InspectionContextRepository(this._inspections);

  final Map<int, WorkshopInspection> _inspections;
  final List<int> requestedIds = [];

  @override
  Future<WorkshopInspection?> getInspection(int id) async {
    requestedIds.add(id);
    return _inspections[id];
  }
}
