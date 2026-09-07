import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_gateway.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_repository.dart';
import 'package:arrow_fleet_manager/config/backend_mode.dart';
import 'package:arrow_fleet_manager/database/database_service.dart';
import 'package:arrow_fleet_manager/database/vehicle_repository.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/vehicle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local mode selects the SQLite repository adapter', () async {
    final service = VehicleService.forMode(
      BackendMode.local,
      localRepository: _FakeLocalRepository(),
    );

    final vehicle = (await service.getVehicles()).single;

    expect(vehicle.id, 9);
    expect(vehicle.identity?.localIdOrNull, 9);
    expect(vehicle.identity?.centralIdOrNull, isNull);
  });

  test(
    'Supabase mode maps central list and never fabricates integer IDs',
    () async {
      final gateway = _FakeBackendGateway([_row()]);
      final service = VehicleService.forMode(
        BackendMode.supabase,
        backendRepository: BackendVehicleRepository(gateway),
      );

      final vehicle = (await service.getVehicles()).single;

      expect(vehicle.id, isNull);
      expect(vehicle.identity?.centralIdOrNull, _id);
    },
  );

  test('central add, edit and lifecycle retain the generated UUID', () async {
    final gateway = _FakeBackendGateway([]);
    final service = VehicleService.forMode(
      BackendMode.supabase,
      backendRepository: BackendVehicleRepository(gateway),
    );
    final added = await service.addVehicle(_vehicle());

    added.model = 'Edited';
    final edited = await service.updateVehicle(added);
    final inactive = await service.deactivateVehicleByIdentity(
      edited.identity!,
    );
    final active = await service.reactivateVehicleByIdentity(
      inactive.identity!,
    );

    expect(added.id, isNull);
    expect(edited.identity, added.identity);
    expect(inactive.identity, added.identity);
    expect(active.identity, added.identity);
    expect(inactive.active, isFalse);
    expect(active.active, isTrue);
    expect(gateway.updatedIds, everyElement(_id));
  });

  test('remote list failure is surfaced without a local fallback', () async {
    final service = VehicleService.forMode(
      BackendMode.supabase,
      backendRepository: BackendVehicleRepository(_FailingBackendGateway()),
    );

    await expectLater(service.getVehicles(), throwsStateError);
  });
}

const _id = '123e4567-e89b-42d3-a456-426614174000';

Vehicle _vehicle() => Vehicle(
  registration: 'MPTEST1',
  fleetNumber: 'MP-001',
  make: 'FleetIQ',
  model: 'Windows Test',
  year: 2026,
  vin: '',
);

Map<String, dynamic> _row({bool active = true}) => {
  'id': _id,
  'legacy_id': null,
  'registration': 'MPTEST1',
  'fleet_number': 'MP-001',
  'make': 'FleetIQ',
  'model': 'Windows Test',
  'manufacture_year': 2026,
  'vin': '',
  'mot_expiry': null,
  'service_due': null,
  'taxi_plate_number': null,
  'taxi_licensing_authority': null,
  'taxi_plate_issue_date': null,
  'taxi_plate_expiry': null,
  'is_active': active,
  'created_at': '2026-09-07T10:00:00Z',
  'updated_at': '2026-09-07T10:00:00Z',
};

class _FakeBackendGateway implements BackendVehicleGateway {
  _FakeBackendGateway(this.rows);

  final List<Map<String, dynamic>> rows;
  final List<String> updatedIds = [];

  @override
  Future<Map<String, dynamic>?> getVehicle(String id) async =>
      rows.where((row) => row['id'] == id).firstOrNull;

  @override
  Future<Map<String, dynamic>> insertVehicle(
    Map<String, dynamic> values,
  ) async {
    final row = {..._row(), ...values};
    rows.add(row);
    return row;
  }

  @override
  Future<List<Map<String, dynamic>>> listVehicles() async => rows;

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  ) async {
    updatedIds.add(id);
    final index = rows.indexWhere((row) => row['id'] == id);
    rows[index] = {...rows[index], ...values};
    return rows[index];
  }
}

class _FailingBackendGateway implements BackendVehicleGateway {
  @override
  Future<Map<String, dynamic>?> getVehicle(String id) =>
      throw StateError('remote failed');

  @override
  Future<Map<String, dynamic>> insertVehicle(Map<String, dynamic> values) =>
      throw StateError('remote failed');

  @override
  Future<List<Map<String, dynamic>>> listVehicles() =>
      throw StateError('remote failed');

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  ) => throw StateError('remote failed');
}

class _FakeLocalRepository extends VehicleRepository {
  _FakeLocalRepository() : super(databaseService: DatabaseService());

  @override
  Future<List<Vehicle>> getVehicles() async => [
    Vehicle(
      id: 9,
      registration: 'LOCAL1',
      fleetNumber: 'L-1',
      make: 'FleetIQ',
      model: 'Local',
      year: 2026,
      vin: '',
    ),
  ];
}
