import 'dart:io';

import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_gateway.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_repository.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_gateway.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_identity.dart';
import 'package:arrow_fleet_manager/features/drivers/services/central_driver_assignment_read_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Supabase assignment mutations use secured RPCs, not direct table writes',
    () {
      final source = File(
        'lib/backend/drivers/supabase_driver_assignment_gateway.dart',
      ).readAsStringSync();

      expect(source, contains("'fleet_assign_driver'"));
      expect(source, contains("'fleet_end_driver_assignment'"));
      expect(source, isNot(contains(".from('driver_assignments').insert")));
      expect(source, isNot(contains(".from('driver_assignments').update")));
    },
  );

  test('reads only assignments for the requested central Driver', () async {
    final assignmentGateway = _AssignmentGateway();
    final vehicleGateway = _VehicleGateway();
    final service = CentralDriverAssignmentReadService(
      assignmentRepository: BackendDriverAssignmentRepository(
        assignmentGateway,
      ),
      vehicleRepository: BackendVehicleRepository(vehicleGateway),
    );

    final assignments = await service.getAssignmentsForDriver(
      DriverIdentity.central(_driverId),
    );

    expect(assignmentGateway.requestedDriverId, _driverId);
    expect(assignments, hasLength(2));
    expect(assignments.first.isCurrent, isTrue);
    expect(assignments.first.vehicleRegistration, 'AB12 CDE');
    expect(assignments.first.vehicleFleetNumber, 'FLEET-1');
    expect(assignments.last.isCurrent, isFalse);
    expect(vehicleGateway.requestedIds, {_vehicleId});
  });

  test('rejects local Driver identity before any central read', () async {
    final assignmentGateway = _AssignmentGateway();
    final service = CentralDriverAssignmentReadService(
      assignmentRepository: BackendDriverAssignmentRepository(
        assignmentGateway,
      ),
      vehicleRepository: BackendVehicleRepository(_VehicleGateway()),
    );

    await expectLater(
      service.getAssignmentsForDriver(DriverIdentity.local(7)),
      throwsUnsupportedError,
    );
    expect(assignmentGateway.requestedDriverId, isNull);
  });

  test(
    'retains assignment row when referenced vehicle is unavailable',
    () async {
      final service = CentralDriverAssignmentReadService(
        assignmentRepository: BackendDriverAssignmentRepository(
          _AssignmentGateway(),
        ),
        vehicleRepository: BackendVehicleRepository(
          _VehicleGateway(returnVehicle: false),
        ),
      );

      final assignments = await service.getAssignmentsForDriver(
        DriverIdentity.central(_driverId),
      );

      expect(assignments, hasLength(2));
      expect(assignments.first.vehicleRegistration, 'Unknown vehicle');
      expect(
        assignments.first.vehicleDescription,
        'Vehicle details unavailable',
      );
    },
  );
}

const _driverId = '123e4567-e89b-42d3-a456-426614174000';
const _vehicleId = '223e4567-e89b-42d3-a456-426614174000';
const _currentAssignmentId = '323e4567-e89b-42d3-a456-426614174000';
const _endedAssignmentId = '423e4567-e89b-42d3-a456-426614174000';

Map<String, dynamic> _assignmentRow({required bool active}) => {
  'id': active ? _currentAssignmentId : _endedAssignmentId,
  'legacy_id': active ? 10 : 9,
  'driver_id': _driverId,
  'vehicle_id': _vehicleId,
  'assigned_from': active ? '2026-09-08T08:00:00Z' : '2026-08-01T08:00:00Z',
  'assigned_to': active ? null : '2026-08-31T18:00:00Z',
  'is_active': active,
  'created_at': '2026-09-08T08:00:00Z',
  'updated_at': '2026-09-08T08:00:00Z',
};

Map<String, dynamic> _vehicleRow() => {
  'id': _vehicleId,
  'legacy_id': 4,
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

class _AssignmentGateway implements BackendDriverAssignmentGateway {
  String? requestedDriverId;

  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForDriver(
    String driverId,
  ) async {
    requestedDriverId = driverId;
    return [_assignmentRow(active: true), _assignmentRow(active: false)];
  }

  @override
  Future<List<Map<String, dynamic>>> listAssignments() async =>
      throw UnsupportedError('Not used by read service.');

  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForVehicle(
    String vehicleId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>?> getAssignment(String id) async =>
      throw UnsupportedError('Not used by read service.');

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
  _VehicleGateway({this.returnVehicle = true});

  final bool returnVehicle;
  final Set<String> requestedIds = <String>{};

  @override
  Future<Map<String, dynamic>?> getVehicle(String id) async {
    requestedIds.add(id);
    return returnVehicle ? _vehicleRow() : null;
  }

  @override
  Future<List<Map<String, dynamic>>> listVehicles() async =>
      throw UnsupportedError('Not used by assignment read service.');

  @override
  Future<Map<String, dynamic>> insertVehicle(
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Not used by assignment read service.');

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  ) async => throw UnsupportedError('Not used by assignment read service.');
}
