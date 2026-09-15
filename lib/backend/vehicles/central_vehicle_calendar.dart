import 'backend_vehicle.dart';

enum CentralVehicleCalendarEventType { mot, service }

class CentralVehicleCalendarEvent {
  const CentralVehicleCalendarEvent({
    required this.date,
    required this.registration,
    required this.type,
  });

  final DateTime date;
  final String registration;
  final CentralVehicleCalendarEventType type;

  String get label => switch (type) {
    CentralVehicleCalendarEventType.mot => 'MOT due',
    CentralVehicleCalendarEventType.service => 'Service due',
  };
}

List<CentralVehicleCalendarEvent> centralVehicleCalendarEvents(
  Iterable<BackendVehicle> vehicles,
) {
  final events = <CentralVehicleCalendarEvent>[];

  for (final vehicle in vehicles.where((vehicle) => vehicle.isActive)) {
    final mot = vehicle.motExpiry;
    if (mot != null) {
      events.add(
        CentralVehicleCalendarEvent(
          date: mot,
          registration: vehicle.registration,
          type: CentralVehicleCalendarEventType.mot,
        ),
      );
    }

    final service = vehicle.serviceDue;
    if (service != null) {
      events.add(
        CentralVehicleCalendarEvent(
          date: service,
          registration: vehicle.registration,
          type: CentralVehicleCalendarEventType.service,
        ),
      );
    }
  }

  events.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    final byRegistration = a.registration.compareTo(b.registration);
    if (byRegistration != 0) return byRegistration;
    return a.type.index.compareTo(b.type.index);
  });

  return events;
}
