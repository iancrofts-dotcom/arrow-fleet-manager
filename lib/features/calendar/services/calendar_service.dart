import '../../vehicles/models/vehicle.dart';
import '../models/calendar_event.dart';

class CalendarService {
  const CalendarService();

  List<CalendarEvent> buildEvents(
    List<Vehicle> vehicles,
  ) {
    final events = <CalendarEvent>[];

    for (final vehicle in vehicles) {
      if (vehicle.motExpiry != null) {
        events.add(
          CalendarEvent(
            title: 'MOT Due',
            subtitle: vehicle.registration,
            date: vehicle.motExpiry!,
            type: CalendarEventType.mot,
          ),
        );
      }

      if (vehicle.serviceDue != null) {
        events.add(
          CalendarEvent(
            title: 'Service Due',
            subtitle: vehicle.registration,
            date: vehicle.serviceDue!,
            type: CalendarEventType.service,
          ),
        );
      }
    }

    events.sort(
      (a, b) => a.date.compareTo(b.date),
    );

    return events;
  }
}