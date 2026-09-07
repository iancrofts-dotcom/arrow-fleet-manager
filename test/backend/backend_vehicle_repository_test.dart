import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_gateway.dart';
import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackendVehicle mapping', () {
    test('maps nullable legacy ID, dates, and taxi fields', () {
      final vehicle = BackendVehicle.fromJson(_row());

      expect(vehicle.id, _id);
      expect(vehicle.legacyId, isNull);
      expect(vehicle.motExpiry, DateTime(2027, 1, 2));
      expect(vehicle.serviceDue, DateTime(2027, 2, 3));
      expect(vehicle.taxiPlateNumber, 'PHV-42');
      expect(vehicle.taxiLicensingAuthority, 'Test Council');
      expect(vehicle.taxiPlateIssueDate, DateTime(2026, 3, 4));
      expect(vehicle.taxiPlateExpiry, DateTime(2027, 3, 4));
    });

    test('accepts nullable optional operational fields', () {
      final vehicle = BackendVehicle.fromJson(
        _row()
          ..['make'] = null
          ..['model'] = null
          ..['manufacture_year'] = null
          ..['vin'] = null
          ..['mot_expiry'] = null
          ..['service_due'] = null
          ..['taxi_plate_number'] = null
          ..['taxi_licensing_authority'] = null
          ..['taxi_plate_issue_date'] = null
          ..['taxi_plate_expiry'] = null,
      );

      expect(vehicle.make, isNull);
      expect(vehicle.motExpiry, isNull);
      expect(vehicle.taxiPlateExpiry, isNull);
    });

    test('fails closed on malformed required data', () {
      expect(
        () => BackendVehicle.fromJson(_row()..['id'] = 'not-a-uuid'),
        throwsFormatException,
      );
      expect(
        () => BackendVehicle.fromJson(_row()..remove('registration')),
        throwsFormatException,
      );
      expect(
        () => BackendVehicle.fromJson(_row()..['is_active'] = 'yes'),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('BackendVehicleRepository', () {
    test('lists and gets vehicles through the gateway', () async {
      final gateway = _FakeGateway([_row()]);
      final repository = BackendVehicleRepository(gateway);

      expect((await repository.listVehicles()).single.id, _id);
      expect((await repository.getVehicle(_id))!.registration, 'AB12 CDE');
      expect(await repository.getVehicle(_missingId), isNull);
    });

    test('insert excludes server-generated identity and timestamps', () async {
      final gateway = _FakeGateway([_row()]);
      final repository = BackendVehicleRepository(gateway);

      await repository.insertVehicle(_write(legacyId: 17));

      expect(gateway.inserted, containsPair('legacy_id', 17));
      expect(gateway.inserted, isNot(contains('id')));
      expect(gateway.inserted, isNot(contains('created_at')));
      expect(gateway.inserted, isNot(contains('updated_at')));
    });

    test(
      'update keeps central and legacy identities out of its payload',
      () async {
        final gateway = _FakeGateway([_row()]);
        final repository = BackendVehicleRepository(gateway);

        await repository.updateVehicle(_id, _write(legacyId: 999));

        expect(gateway.updatedId, _id);
        expect(gateway.updated, isNot(contains('id')));
        expect(gateway.updated, isNot(contains('legacy_id')));
        expect(gateway.updated, isNot(contains('created_at')));
        expect(gateway.updated, isNot(contains('updated_at')));
      },
    );

    test('serializes operational dates as PostgreSQL date values', () {
      final payload = _write().toInsertJson();

      expect(payload['mot_expiry'], '2027-01-02');
      expect(payload['service_due'], '2027-02-03');
      expect(payload['taxi_plate_issue_date'], '2026-03-04');
      expect(payload['taxi_plate_expiry'], '2027-03-04');
    });
  });
}

const _id = '123e4567-e89b-42d3-a456-426614174000';
const _missingId = '123e4567-e89b-42d3-a456-426614174001';

Map<String, dynamic> _row() => {
  'id': _id,
  'legacy_id': null,
  'registration': 'AB12 CDE',
  'fleet_number': 'F-42',
  'make': 'Example',
  'model': 'Van',
  'manufacture_year': 2024,
  'vin': 'VIN42',
  'mot_expiry': '2027-01-02',
  'service_due': '2027-02-03',
  'taxi_plate_number': 'PHV-42',
  'taxi_licensing_authority': 'Test Council',
  'taxi_plate_issue_date': '2026-03-04',
  'taxi_plate_expiry': '2027-03-04',
  'is_active': true,
  'created_at': '2026-09-07T10:00:00Z',
  'updated_at': '2026-09-07T10:00:00Z',
};

BackendVehicleWrite _write({int? legacyId}) => BackendVehicleWrite(
  legacyId: legacyId,
  registration: 'AB12 CDE',
  fleetNumber: 'F-42',
  make: 'Example',
  model: 'Van',
  manufactureYear: 2024,
  vin: 'VIN42',
  motExpiry: DateTime(2027, 1, 2, 14),
  serviceDue: DateTime(2027, 2, 3, 15),
  taxiPlateNumber: 'PHV-42',
  taxiLicensingAuthority: 'Test Council',
  taxiPlateIssueDate: DateTime(2026, 3, 4, 16),
  taxiPlateExpiry: DateTime(2027, 3, 4, 17),
);

class _FakeGateway implements BackendVehicleGateway {
  _FakeGateway(this.rows);

  final List<Map<String, dynamic>> rows;
  Map<String, dynamic> inserted = {};
  Map<String, dynamic> updated = {};
  String? updatedId;

  @override
  Future<Map<String, dynamic>?> getVehicle(String id) async =>
      rows.where((row) => row['id'] == id).firstOrNull;

  @override
  Future<Map<String, dynamic>> insertVehicle(
    Map<String, dynamic> values,
  ) async {
    inserted = values;
    return rows.single;
  }

  @override
  Future<List<Map<String, dynamic>>> listVehicles() async => rows;

  @override
  Future<Map<String, dynamic>> updateVehicle(
    String id,
    Map<String, dynamic> values,
  ) async {
    updatedId = id;
    updated = values;
    return rows.single;
  }
}
