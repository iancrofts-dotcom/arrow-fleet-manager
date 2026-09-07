import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_mapper.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VehicleIdentity', () {
    test('represents local identity without a central UUID', () {
      final identity = VehicleIdentity.local(42);

      expect(identity.kind, VehicleIdentityKind.local);
      expect(identity.localIdOrNull, 42);
      expect(identity.centralIdOrNull, isNull);
      expect(identity.requireLocalId('assignment lookup'), 42);
    });

    test('represents normalized central UUID without a local ID', () {
      final identity = VehicleIdentity.central(_uppercaseId);

      expect(identity.kind, VehicleIdentityKind.central);
      expect(identity.localIdOrNull, isNull);
      expect(identity.centralIdOrNull, _id);
      expect(
        () => identity.requireLocalId('document lookup'),
        throwsUnsupportedError,
      );
    });

    test('rejects malformed central UUIDs and local IDs', () {
      expect(
        () => VehicleIdentity.central('not-a-uuid'),
        throwsFormatException,
      );
      expect(() => VehicleIdentity.local(0), throwsArgumentError);
    });

    test('has deterministic value equality and hashes', () {
      final first = VehicleIdentity.central(_id);
      final second = VehicleIdentity.central(_uppercaseId);

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(VehicleIdentity.local(1), VehicleIdentity.local(1));
      expect(VehicleIdentity.local(1), isNot(VehicleIdentity.local(2)));
    });
  });

  test('existing local Vehicle id creates an explicit local identity', () {
    final vehicle = _localVehicle(id: 7);

    expect(vehicle.id, 7);
    expect(vehicle.identity, VehicleIdentity.local(7));
  });

  test('central Vehicle cannot also carry a SQLite id', () {
    expect(
      () => _localVehicle(id: 7, identity: VehicleIdentity.central(_id)),
      throwsArgumentError,
    );
  });

  test('central Vehicle cannot enter SQLite serialization', () {
    final vehicle = _backendVehicle().toAppVehicle();

    expect(vehicle.toMap, throwsUnsupportedError);
  });

  test('BackendVehicle mapping retains UUID and fabricates no integer id', () {
    final vehicle = _backendVehicle().toAppVehicle();

    expect(vehicle.id, isNull);
    expect(vehicle.identity?.centralIdOrNull, _id);
    expect(vehicle.identity?.localIdOrNull, isNull);
    expect(vehicle.registration, 'AB12 CDE');
    expect(vehicle.taxiPlateNumber, 'PHV-42');
  });
}

const _id = '123e4567-e89b-42d3-a456-426614174000';
const _uppercaseId = '123E4567-E89B-42D3-A456-426614174000';

Vehicle _localVehicle({int? id, VehicleIdentity? identity}) => Vehicle(
  id: id,
  identity: identity,
  registration: 'AB12 CDE',
  fleetNumber: 'F-42',
  make: 'FleetIQ',
  model: 'Test',
  year: 2026,
  vin: 'VIN42',
);

BackendVehicle _backendVehicle() => BackendVehicle(
  id: _id,
  registration: 'AB12 CDE',
  fleetNumber: 'F-42',
  make: 'FleetIQ',
  model: 'Central',
  manufactureYear: 2026,
  vin: 'VIN42',
  taxiPlateNumber: 'PHV-42',
  isActive: true,
  createdAt: DateTime.utc(2026, 9, 7),
  updatedAt: DateTime.utc(2026, 9, 7),
);
