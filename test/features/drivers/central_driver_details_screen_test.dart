import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_gateway.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_repository.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_gateway.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_identity.dart';
import 'package:arrow_fleet_manager/features/drivers/screens/central_driver_details_screen.dart';
import 'package:arrow_fleet_manager/features/drivers/services/central_driver_assignment_read_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('central Driver details shows central assignment history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = CentralDriverAssignmentReadService(
      assignmentRepository: BackendDriverAssignmentRepository(
        _AssignmentGateway(),
      ),
      vehicleRepository: BackendVehicleRepository(_VehicleGateway()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CentralDriverDetailsScreen(
          driver: Driver(
            identity: DriverIdentity.central(_driverId),
            firstName: 'FleetIQ',
            lastName: 'Test Driver',
            licenceNumber: 'TEST5D1',
          ),
          assignmentReadService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('FleetIQ Test Driver'), findsOneWidget);
    expect(find.text('Vehicle assignments'), findsOneWidget);
    expect(find.text('AB12 CDE · FLEET-1'), findsOneWidget);
    expect(find.text('Current'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}

const _driverId = '123e4567-e89b-42d3-a456-426614174000';
const _vehicleId = '223e4567-e89b-42d3-a456-426614174000';
const _assignmentId = '323e4567-e89b-42d3-a456-426614174000';

class _AssignmentGateway implements BackendDriverAssignmentGateway {
  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForDriver(
    String driverId,
  ) async => [
    {
      'id': _assignmentId,
      'legacy_id': 3,
      'driver_id': _driverId,
      'vehicle_id': _vehicleId,
      'assigned_from': '2026-09-08T08:00:00Z',
      'assigned_to': null,
      'is_active': true,
      'created_at': '2026-09-08T08:00:00Z',
      'updated_at': '2026-09-08T08:00:00Z',
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> listAssignments() async => const [];

  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForVehicle(
    String vehicleId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>?> getAssignment(String id) async => null;

  @override
  Future<Map<String, dynamic>> insertAssignment(
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Assignment writes are disabled.');

  @override
  Future<Map<String, dynamic>> updateAssignment(
    String id,
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Assignment writes are disabled.');
}

class _VehicleGateway implements BackendVehicleGateway {
  @override
  Future<Map<String, dynamic>?> getVehicle(String id) async => {
    'id': _vehicleId,
    'legacy_id': 1,
    'registration': 'AB12 CDE',
    'fleet_number': 'FLEET-1',
    'make': 'Ford',
    'model': 'Transit',
    'manufacture_year': 2024,
    'vin': null,
    'mot_expiry': null,
    'service_due': null,
    'taxi_plate_number': null,
    'taxi_licensing_authority': null,
    'taxi_plate_issue_date': null,
    'taxi_plate_expiry': null,
    'is_active': true,
    'created_at': '2026-09-07T08:00:00Z',
    'updated_at': '2026-09-07T08:00:00Z',
  };

  @override
  Future<List<Map<String, dynamic>>> listVehicles() async => const [];

  @override
  Future<Map<String, dynamic>> insertVehicle(
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Not used.');

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Not used.');
}
