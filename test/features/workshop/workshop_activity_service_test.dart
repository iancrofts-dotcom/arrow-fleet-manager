import 'package:arrow_fleet_manager/features/workshop/models/repair_job.dart';
import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'package:arrow_fleet_manager/features/workshop/repositories/workshop_repository.dart';
import 'package:arrow_fleet_manager/features/workshop/screens/workshop_activity_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recent workshop activity is timestamp-backed, newest first, and limited',
      () async {
    final service = WorkshopActivityService(WorkshopRepository());
    final now = DateTime(2026, 8, 15, 12);
    final inspections = List.generate(6, (index) {
      return WorkshopInspection(
        id: index + 1,
        inspectionNumber: 'IN-${index + 1}',
        vehicleId: index + 1,
        registration: 'AB${index + 10} CDE',
        fleetNumber: 'F${index + 1}',
        technicianName: '',
        inspectionType: WorkshopInspectionType.driverDailyInspection,
        status: WorkshopInspectionStatus.signedOff,
        vehicleStatus: VehicleWorkshopStatus.roadworthy,
        dateStarted: now.subtract(Duration(hours: index + 1)),
        dateCompleted: now.subtract(Duration(hours: index + 1)),
        mileage: 0,
        overallResult: InspectionResult.pass,
        inspectionScore: 100,
        criticalFailures: 0,
        advisories: 0,
        repairsRequired: 0,
        labourHours: 0,
        totalCost: 0,
        notes: '',
        managerSignature: 'Manager',
        createdAt: now.subtract(Duration(hours: index + 1)),
        updatedAt: now.subtract(Duration(hours: index + 1)),
      );
    });
    final repairJobs = List.generate(3, (index) {
      return RepairJob(
        id: index + 1,
        jobNumber: 'RJ-${index + 1}',
        inspectionId: index + 1,
        inspectionItemId: index + 1,
        vehicleId: index + 1,
        vehicleRegistration: 'AB${index + 10} CDE',
        title: 'Repair',
        description: 'Repair required',
        status: RepairJobStatus.completed,
        createdAt: now.subtract(Duration(minutes: index + 1)),
        startedAt: now.subtract(Duration(minutes: index + 1)),
        completedAt: now.subtract(Duration(minutes: index + 1)),
      );
    });

    final activity = await service.getRecentActivity(
      inspections: inspections,
      repairJobs: repairJobs,
    );

    expect(activity, hasLength(10));
    expect(activity.first.dateTime, now.subtract(const Duration(minutes: 1)));
    expect(activity.any((event) => event.type == 'repairStarted'), isTrue);
    expect(activity.any((event) => event.type == 'inspectionSignedOff'), isTrue);
  });
}
