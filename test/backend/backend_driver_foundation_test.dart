import 'package:arrow_fleet_manager/backend/drivers/backend_driver.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_gateway.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_assignment_repository.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_gateway.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_mapper.dart';
import 'package:arrow_fleet_manager/backend/drivers/backend_driver_repository.dart';
import 'package:arrow_fleet_manager/backend/backend_profile.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_entity.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DriverIdentity', () {
    test('validates local and central identities without conversion', () {
      final local = DriverIdentity.local(7);
      final central = DriverIdentity.central(_driverId.toUpperCase());
      expect(local.localIdOrNull, 7);
      expect(local.centralIdOrNull, isNull);
      expect(central.centralIdOrNull, _driverId);
      expect(central.localIdOrNull, isNull);
      expect(
        () => central.requireLocalId('SQLite lookup'),
        throwsUnsupportedError,
      );
      expect(() => DriverIdentity.local(0), throwsArgumentError);
      expect(() => DriverIdentity.central('invalid'), throwsFormatException);
      expect(DriverIdentity.central(_driverId), central);
    });
  });

  test('central DTO maps to Driver with UUID and no integer ID', () {
    final driver = BackendDriver.fromJson(_driverRow()).toAppDriver();
    expect(driver.id, isNull);
    expect(driver.identity?.centralIdOrNull, _driverId);
    expect(driver.toMap, throwsUnsupportedError);
    expect(() => DriverEntity.fromDriver(driver), throwsUnsupportedError);
  });

  test('driver write excludes server-owned identity and timestamps', () {
    const write = BackendDriverWrite(
      firstName: 'Alex',
      lastName: 'Driver',
      licenceNumber: 'LIC-1',
    );
    final payload = write.toInsertJson();
    expect(payload, isNot(contains('id')));
    expect(payload, isNot(contains('created_at')));
    expect(payload, isNot(contains('updated_at')));
  });

  test('profile parses optional central driver linkage', () {
    final profile = BackendProfile.fromJson({
      'id': _profileId,
      'username': 'alex',
      'role': 'driver',
      'is_active': true,
      'driver_legacy_id': 7,
      'driver_id': _driverId,
    });
    expect(profile.driverLegacyId, 7);
    expect(profile.driverId, _driverId);
  });

  test('assignment maps UUID relationships and history', () {
    final active = BackendDriverAssignment.fromJson(_assignmentRow());
    final ended = BackendDriverAssignment.fromJson(
      _assignmentRow(active: false),
    );
    expect(active.driverId, _driverId);
    expect(active.vehicleId, _vehicleId);
    expect(active.assignedTo, isNull);
    expect(ended.assignedTo, isNotNull);
    expect(ended.isActive, isFalse);
  });

  test('repository payloads exclude generated assignment identity', () async {
    final gateway = _AssignmentGateway();
    await BackendDriverAssignmentRepository(gateway).insertAssignment(
      BackendDriverAssignmentWrite(
        driverId: _driverId,
        vehicleId: _vehicleId,
        assignedFrom: DateTime.utc(2026, 9, 7),
      ),
    );
    expect(gateway.inserted, isNot(contains('id')));
    expect(gateway.inserted, isNot(contains('created_at')));
  });

  test('remote driver failure propagates without fallback', () async {
    final repository = BackendDriverRepository(_FailingDriverGateway());
    await expectLater(repository.listDrivers(), throwsStateError);
  });
}

const _driverId = '123e4567-e89b-42d3-a456-426614174000';
const _vehicleId = '223e4567-e89b-42d3-a456-426614174000';
const _assignmentId = '323e4567-e89b-42d3-a456-426614174000';
const _profileId = '423e4567-e89b-42d3-a456-426614174000';
Map<String, dynamic> _driverRow() => {
  'id': _driverId,
  'legacy_id': 7,
  'first_name': 'Alex',
  'last_name': 'Driver',
  'licence_number': 'LIC-1',
  'licence_expiry': null,
  'phone': null,
  'email': null,
  'username': 'alex',
  'is_active': true,
  'created_at': '2026-09-07T10:00:00Z',
  'updated_at': '2026-09-07T10:00:00Z',
};
Map<String, dynamic> _assignmentRow({bool active = true}) => {
  'id': _assignmentId,
  'legacy_id': 3,
  'driver_id': _driverId,
  'vehicle_id': _vehicleId,
  'assigned_from': '2026-09-07T10:00:00Z',
  'assigned_to': active ? null : '2026-09-08T10:00:00Z',
  'is_active': active,
  'created_at': '2026-09-07T10:00:00Z',
  'updated_at': '2026-09-07T10:00:00Z',
};

class _AssignmentGateway implements BackendDriverAssignmentGateway {
  Map<String, dynamic> inserted = {};
  @override
  Future<Map<String, dynamic>> insertAssignment(
    Map<String, dynamic> values,
  ) async {
    inserted = values;
    return {..._assignmentRow(), ...values};
  }

  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForVehicle(
    String vehicleId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>?> getAssignment(String id) async => null;
  @override
  Future<List<Map<String, dynamic>>> listAssignments() async => [];
  @override
  Future<List<Map<String, dynamic>>> listAssignmentsForDriver(
    String driverId,
  ) async => [];
  @override
  Future<Map<String, dynamic>> updateAssignment(
    String id,
    Map<String, dynamic> values,
  ) async => {..._assignmentRow(), ...values};
}

class _FailingDriverGateway implements BackendDriverGateway {
  @override
  Future<List<Map<String, dynamic>>> listDrivers() =>
      throw StateError('remote failed');
  @override
  Future<Map<String, dynamic>?> getDriver(String id) =>
      throw StateError('remote failed');
  @override
  Future<Map<String, dynamic>> insertDriver(Map<String, dynamic> values) =>
      throw StateError('remote failed');
  @override
  Future<Map<String, dynamic>> updateDriver(
    String id,
    Map<String, dynamic> values,
  ) => throw StateError('remote failed');
}
