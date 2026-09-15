import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validVehicleJson({Object? fleetNumber = 'FLEET-1'}) => {
    'id': '6ac4a635-24e7-41ff-8494-23fb86d3c340',
    'legacy_id': null,
    'registration': 'YN19 ZOW',
    'fleet_number': fleetNumber,
    'make': null,
    'model': null,
    'manufacture_year': null,
    'vin': null,
    'mot_expiry': null,
    'service_due': null,
    'taxi_plate_number': null,
    'taxi_licensing_authority': null,
    'taxi_plate_issue_date': null,
    'taxi_plate_expiry': null,
    'mot_type': 'standard',
    'psv_garage_check_enabled': false,
    'psv_garage_check_interval_weeks': 6,
    'psv_garage_check_last_date': null,
    'psv_garage_check_due': null,
    'taxi_safety_check_enabled': false,
    'taxi_safety_check_interval_weeks': 6,
    'taxi_safety_check_last_date': null,
    'taxi_safety_check_due': null,
    'is_active': true,
    'created_at': '2026-09-12T20:24:15.606903+00:00',
    'updated_at': '2026-09-12T20:24:15.606903+00:00',
  };

  group('BackendVehicle.fromJson fleet number', () {
    test('accepts a blank fleet number', () {
      final vehicle = BackendVehicle.fromJson(
        validVehicleJson(fleetNumber: ''),
      );

      expect(vehicle.registration, 'YN19 ZOW');
      expect(vehicle.fleetNumber, '');
    });

    test('normalises a null fleet number to empty string', () {
      final vehicle = BackendVehicle.fromJson(
        validVehicleJson(fleetNumber: null),
      );

      expect(vehicle.fleetNumber, '');
    });

    test('preserves a valid fleet number', () {
      final vehicle = BackendVehicle.fromJson(
        validVehicleJson(fleetNumber: 'FLEET-1'),
      );

      expect(vehicle.fleetNumber, 'FLEET-1');
    });

    test('still rejects a non-string fleet number', () {
      expect(
        () => BackendVehicle.fromJson(validVehicleJson(fleetNumber: 123)),
        throwsFormatException,
      );
    });
  });

  test('still rejects a blank registration', () {
    final json = validVehicleJson()..['registration'] = '';

    expect(() => BackendVehicle.fromJson(json), throwsFormatException);
  });

  test('still rejects an invalid vehicle id', () {
    final json = validVehicleJson()..['id'] = 'not-a-uuid';

    expect(() => BackendVehicle.fromJson(json), throwsFormatException);
  });
}
