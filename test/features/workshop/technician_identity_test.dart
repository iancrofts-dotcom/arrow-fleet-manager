import 'package:arrow_fleet_manager/features/workshop/models/repair_job.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RepairJob technician identity', () {
    test('preserves an opaque user ID when serializing a new assignment', () {
      final job = RepairJob(
        jobNumber: 'RJ-1',
        inspectionId: 1,
        inspectionItemId: 1,
        vehicleId: 1,
        vehicleRegistration: 'AB12 CDE',
        title: 'Repair',
        description: 'Repair required',
        technicianId: 'tech-a1b2',
        technicianName: 'Technician A',
        createdAt: DateTime(2026),
      );

      expect(job.toMap()['technicianId'], 'tech-a1b2');
    });

    test('loads a legacy numeric technician ID as text', () {
      final job = RepairJob.fromMap({
        'id': 1,
        'jobNumber': 'RJ-1',
        'inspectionId': 1,
        'inspectionItemId': 1,
        'vehicleId': 1,
        'vehicleRegistration': 'AB12 CDE',
        'title': 'Repair',
        'description': 'Repair required',
        'priority': 'medium',
        'status': 'assigned',
        'technicianId': 42,
        'technicianName': 'Legacy Technician',
        'partsRequired': 0,
        'estimatedHours': 0,
        'actualHours': 0,
        'estimatedCost': 0,
        'actualCost': 0,
        'roadworthy': 0,
        'createdAt': DateTime(2026).toIso8601String(),
        'startedAt': null,
        'completedAt': null,
      });

      expect(job.technicianId, '42');
    });

    test('keeps a legacy name-only job unassigned', () {
      final job = RepairJob.fromMap({
        'id': 1,
        'jobNumber': 'RJ-1',
        'inspectionId': 1,
        'inspectionItemId': 1,
        'vehicleId': 1,
        'vehicleRegistration': 'AB12 CDE',
        'title': 'Repair',
        'description': 'Repair required',
        'priority': 'medium',
        'status': 'open',
        'technicianId': null,
        'technicianName': 'Legacy Technician',
        'partsRequired': 0,
        'estimatedHours': 0,
        'actualHours': 0,
        'estimatedCost': 0,
        'actualCost': 0,
        'roadworthy': 0,
        'createdAt': DateTime(2026).toIso8601String(),
        'startedAt': null,
        'completedAt': null,
      });

      expect(job.technicianId, isNull);
      expect(job.technicianName, 'Legacy Technician');
    });
  });
}
