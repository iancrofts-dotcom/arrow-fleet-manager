import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_gateway.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_repository.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_gateway.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_repository.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle_identity.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/central_vehicle_assignment_read_service.dart';
import 'package:arrow_fleet_manager/features/vehicles/widgets/central_vehicle_assignments_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('central Vehicle section shows read-only Driver assignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = CentralVehicleAssignmentReadService(
      assignmentRepository: BackendDriverAssignmentRepository(
        _AssignmentGateway(),
      ),
      driverRepository: BackendDriverRepository(_DriverGateway()),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: CentralVehicleAssignmentsSection(
              vehicleIdentity: VehicleIdentity.central(_vehicleId),
              assignmentReadService: service,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Driver assignments'), findsOneWidget);
    expect(find.text('FleetIQ Test Driver · TEST5D1'), findsOneWidget);
    expect(find.text('Current'), findsWidgets);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byIcon(Icons.person_add), findsNothing);
  });
}

const _driverId = '123e4567-e89b-42d3-a456-426614174000';
const _vehicleId = '223e4567-e89b-42d3-a456-426614174000';
const _assignmentId = '323e4567-e89b-42d3-a456-426614174000';

class _AssignmentGateway implements BackendDriverAssignmentGateway {
  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForVehicle(
    String vehicleId,
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
  Future<List<Map<String, dynamic>>> listAssignmentsForDriver(
    String driverId,
  ) async => const [];

  @override
  Future<List<Map<String, dynamic>>> listAssignments() async => const [];

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

class _DriverGateway implements BackendDriverGateway {
  @override
  Future<Map<String, dynamic>?> getDriver(String id) async => {
    'id': _driverId,
    'legacy_id': 7,
    'first_name': 'FleetIQ',
    'last_name': 'Test Driver',
    'licence_number': 'TEST5D1',
    'licence_expiry': null,
    'phone': null,
    'email': null,
    'username': 'test5d1',
    'is_active': true,
    'created_at': '2026-09-07T08:00:00Z',
    'updated_at': '2026-09-07T08:00:00Z',
  };

  @override
  Future<List<Map<String, dynamic>>> listDrivers() async => const [];

  @override
  Future<Map<String, dynamic>> insertDriver(
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Not used.');

  @override
  Future<Map<String, dynamic>> updateDriver(
    String id,
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Not used.');
}
