import 'calendar_event.dart';

enum CalendarFilter {
  all,
  vehicles,
  maintenance,
  documents,
  drivers,
}

extension CalendarFilterExtension on CalendarFilter {
  String get label {
    switch (this) {
      case CalendarFilter.all:
        return 'All';

      case CalendarFilter.vehicles:
        return 'Vehicles';

      case CalendarFilter.maintenance:
        return 'Maintenance';

      case CalendarFilter.documents:
        return 'Documents';

      case CalendarFilter.drivers:
        return 'Drivers';
    }
  }

  bool matches(CalendarEvent event) {
    switch (this) {
      case CalendarFilter.all:
        return true;

      case CalendarFilter.vehicles:
        return event.type == CalendarEventType.vehicle;

      case CalendarFilter.maintenance:
        return event.type == CalendarEventType.maintenance;

      case CalendarFilter.documents:
        return event.type == CalendarEventType.document;

      case CalendarFilter.drivers:
        return event.type == CalendarEventType.licence ||
            event.type == CalendarEventType.cpc ||
            event.type == CalendarEventType.medical;
    }
  }
}