import 'package:arrow_fleet_manager/features/dashboard/models/dashboard_activity.dart';
import 'package:arrow_fleet_manager/features/dashboard/services/driver_daily_check_activity_service.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = DriverDailyCheckActivityService();
  final now = DateTime(2026, 9, 4, 7, 42);

  test(
    'maps completed passing daily checks from persisted workshop data',
    () async {
      final activities = await service.getRecentActivities(
        inspections: [
          _inspection(
            id: 11,
            completedAt: now,
            status: WorkshopInspectionStatus.completed,
            result: InspectionResult.pass,
          ),
        ],
      );

      expect(activities, hasLength(1));
      expect(activities.single.title, 'Daily check completed');
      expect(activities.single.subtitle, 'John Smith - AB12 CDE - Passed');
      expect(activities.single.date, now);
      expect(activities.single.type, DashboardActivityType.dailyCheck);
      expect(activities.single.entityId, '11');
      expect(activities.single.driverId, 20);
      expect(activities.single.vehicleId, 10);
    },
  );

  test('includes completed daily checks with reported defects', () async {
    final activities = await service.getRecentActivities(
      inspections: [
        _inspection(
          completedAt: now,
          status: WorkshopInspectionStatus.awaitingRepair,
          result: InspectionResult.fail,
          repairsRequired: 2,
        ),
      ],
    );

    expect(activities.single.subtitle, contains('Defects reported'));
  });

  test('excludes incomplete and non-daily workshop inspections', () async {
    final activities = await service.getRecentActivities(
      inspections: [
        _inspection(completedAt: null),
        _inspection(
          completedAt: now,
          type: WorkshopInspectionType.defectInspection,
        ),
      ],
    );

    expect(activities, isEmpty);
  });

  test(
    'sorts by completion timestamp and applies the requested limit',
    () async {
      final activities = await service.getRecentActivities(
        inspections: [
          _inspection(
            id: 1,
            completedAt: now.subtract(const Duration(hours: 2)),
          ),
          _inspection(id: 2, completedAt: now),
          _inspection(
            id: 3,
            completedAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
        limit: 2,
      );

      expect(activities.map((activity) => activity.entityId), ['2', '3']);
    },
  );
}

WorkshopInspection _inspection({
  int? id,
  DateTime? completedAt,
  WorkshopInspectionType type = WorkshopInspectionType.driverDailyInspection,
  WorkshopInspectionStatus status = WorkshopInspectionStatus.completed,
  InspectionResult result = InspectionResult.pass,
  int repairsRequired = 0,
}) {
  final startedAt = DateTime(2026, 9, 4, 7);
  return WorkshopInspection(
    id: id,
    inspectionNumber: 'DD-${id ?? 1}',
    vehicleId: 10,
    registration: 'AB12 CDE',
    fleetNumber: 'F10',
    technicianName: '',
    driverId: 20,
    driverName: 'John Smith',
    inspectionType: type,
    status: status,
    vehicleStatus: VehicleWorkshopStatus.awaitingRepair,
    dateStarted: startedAt,
    dateCompleted: completedAt,
    mileage: 1000,
    overallResult: result,
    inspectionScore: result == InspectionResult.pass ? 100 : 60,
    criticalFailures: 0,
    advisories: 0,
    repairsRequired: repairsRequired,
    labourHours: 0,
    totalCost: 0,
    notes: '',
    createdAt: startedAt,
    updatedAt: completedAt ?? startedAt,
  );
}
