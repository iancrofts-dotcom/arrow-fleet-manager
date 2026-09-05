import 'package:arrow_fleet_manager/features/calendar/mappers/vehicle_calendar_mapper.dart';
import 'package:arrow_fleet_manager/features/calendar/models/calendar_event.dart';
import 'package:arrow_fleet_manager/features/calendar/services/calendar_event_navigator.dart';
import 'package:arrow_fleet_manager/features/calendar/widgets/calendar_event_list.dart';
import 'package:arrow_fleet_manager/features/vehicles/models/vehicle.dart';
import 'package:arrow_fleet_manager/features/vehicles/services/vehicle_service.dart';
import 'package:arrow_fleet_manager/features/drivers/models/driver.dart';
import 'package:arrow_fleet_manager/features/drivers/services/driver_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'vehicle calendar events retain persisted IDs despite duplicate registrations',
    () {
      final events = const VehicleCalendarMapper().map([
        _vehicle(
          id: 10,
          registration: 'DUP123',
          motExpiry: DateTime(2026, 6, 1),
        ),
        _vehicle(
          id: 20,
          registration: 'DUP123',
          serviceDue: DateTime(2026, 6, 2),
        ),
      ]);

      expect(
        events.singleWhere((event) => event.title == 'MOT Due').vehicleId,
        10,
      );
      expect(
        events.singleWhere((event) => event.title == 'Service Due').vehicleId,
        20,
      );
    },
  );

  testWidgets(
    'vehicle event opens its persisted Vehicle and returns to Calendar',
    (tester) async {
      final vehicle = _vehicle(id: 42, registration: 'VEH042');
      final event = _event(vehicleId: 42);
      final navigator = CalendarEventNavigator(
        vehicleService: _FakeVehicleService(vehicle),
        vehicleDetailsBuilder: (vehicle) => Scaffold(
          appBar: AppBar(title: const Text('Vehicle Details')),
          body: Text('Vehicle ID: ${vehicle.id}'),
        ),
      );

      await tester.pumpWidget(_source(navigator, event));

      await tester.tap(find.text('MOT Due'));
      await tester.pumpAndSettle();

      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(find.text('Vehicle ID: 42'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('MOT Due'), findsOneWidget);
      expect(find.text('Vehicle ID: 42'), findsNothing);
    },
  );

  testWidgets('service event opens the Vehicle identified by its ID', (
    tester,
  ) async {
    final vehicle = _vehicle(id: 73, registration: 'VEH073');
    final navigator = CalendarEventNavigator(
      vehicleService: _FakeVehicleService(vehicle),
      vehicleDetailsBuilder: (vehicle) => Scaffold(
        appBar: AppBar(title: const Text('Vehicle Details')),
        body: Text('Vehicle ID: ${vehicle.id}'),
      ),
    );

    await tester.pumpWidget(
      _source(navigator, _event(vehicleId: 73, title: 'Service Due')),
    );

    await tester.tap(find.text('Service Due'));
    await tester.pumpAndSettle();

    expect(find.text('Vehicle ID: 73'), findsOneWidget);
  });

  testWidgets('missing Vehicle keeps the Calendar route open', (tester) async {
    final navigator = CalendarEventNavigator(
      vehicleService: _FakeVehicleService(null),
      vehicleDetailsBuilder: (_) => const Placeholder(),
    );

    await tester.pumpWidget(_source(navigator, _event(vehicleId: 42)));

    await tester.tap(find.text('MOT Due'));
    await tester.pump();

    expect(find.text('MOT Due'), findsOneWidget);
    expect(find.text('This vehicle is no longer available.'), findsOneWidget);
  });

  testWidgets('compliance event opens the Driver identified by its ID', (
    tester,
  ) async {
    final navigator = CalendarEventNavigator(
      driverService: _FakeDriverService(_driver(id: 9)),
      driverDetailsBuilder: (driver) => Scaffold(
        appBar: AppBar(title: const Text('Driver Details')),
        body: Text('Driver ID: ${driver.id}'),
      ),
    );
    final event = CalendarEvent(
      title: 'CPC Renewal',
      subtitle: 'Driver',
      date: DateTime(2026, 6, 1),
      type: CalendarEventType.cpc,
      icon: Icons.school,
      color: Colors.orange,
      driverId: 9,
    );

    await tester.pumpWidget(_source(navigator, event));
    await tester.tap(find.text('CPC Renewal'));
    await tester.pumpAndSettle();

    expect(find.text('Driver ID: 9'), findsOneWidget);
  });
}

Widget _source(CalendarEventNavigator navigator, CalendarEvent event) {
  return MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: CalendarEventList(
          events: [event],
          onEventTap: (selected) {
            navigator.openDetails(context, selected);
          },
        ),
      ),
    ),
  );
}

CalendarEvent _event({required int vehicleId, String title = 'MOT Due'}) =>
    CalendarEvent(
      title: title,
      subtitle: 'Vehicle',
      date: DateTime(2026, 6, 1),
      type: CalendarEventType.vehicle,
      icon: Icons.directions_car,
      color: Colors.blue,
      vehicleId: vehicleId,
    );

Vehicle _vehicle({
  required int id,
  required String registration,
  DateTime? motExpiry,
  DateTime? serviceDue,
}) => Vehicle(
  id: id,
  registration: registration,
  fleetNumber: 'F$id',
  make: 'Arrow',
  model: 'Fleet',
  year: 2024,
  vin: 'VIN$id',
  motExpiry: motExpiry,
  serviceDue: serviceDue,
);

class _FakeVehicleService extends VehicleService {
  _FakeVehicleService(this.vehicle);

  final Vehicle? vehicle;

  @override
  Future<Vehicle?> getVehicleById(int id) async {
    return vehicle?.id == id ? vehicle : null;
  }
}

Driver _driver({required int id}) => Driver(
  id: id,
  firstName: 'Test',
  lastName: 'Driver',
  licenceNumber: 'LIC-$id',
);

class _FakeDriverService extends DriverService {
  _FakeDriverService(this.driver);

  final Driver? driver;

  @override
  Future<Driver?> getDriverById(int id) async =>
      driver?.id == id ? driver : null;
}
