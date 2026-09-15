import 'package:arrow_fleet_manager/backend/vehicles/backend_vehicle.dart';
import 'package:arrow_fleet_manager/backend/vehicles/central_vehicle_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('central calendar emits MOT and service events for active vehicles', () {
    final events = centralVehicleCalendarEvents([
      _vehicle(
        id: 'active',
        registration: 'TEST5D1',
        motExpiry: DateTime(2026, 9, 20),
        serviceDue: DateTime(2026, 9, 10),
      ),
      _vehicle(
        id: 'inactive',
        registration: 'OLD1',
        isActive: false,
        motExpiry: DateTime(2026, 9, 9),
        serviceDue: DateTime(2026, 9, 11),
      ),
    ]);

    expect(events, hasLength(2));
    expect(events[0].registration, 'TEST5D1');
    expect(events[0].label, 'Service due');
    expect(events[0].date, DateTime(2026, 9, 10));
    expect(events[1].label, 'MOT due');
    expect(events[1].date, DateTime(2026, 9, 20));
  });

  test(
    'central calendar ignores missing dates and sorts deterministically',
    () {
      final events = centralVehicleCalendarEvents([
        _vehicle(
          id: 'b',
          registration: 'ZZ02 ZZZ',
          motExpiry: DateTime(2026, 10, 1),
        ),
        _vehicle(
          id: 'a',
          registration: 'AA01 AAA',
          motExpiry: DateTime(2026, 10, 1),
        ),
        _vehicle(id: 'none', registration: 'NONE1'),
      ]);

      expect(events.map((event) => event.registration), [
        'AA01 AAA',
        'ZZ02 ZZZ',
      ]);
    },
  );
}

BackendVehicle _vehicle({
  required String id,
  required String registration,
  bool isActive = true,
  DateTime? motExpiry,
  DateTime? serviceDue,
}) => BackendVehicle(
  id: id,
  registration: registration,
  fleetNumber: 'F-$id',
  make: 'Test',
  model: 'Vehicle',
  isActive: isActive,
  motExpiry: motExpiry,
  serviceDue: serviceDue,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
