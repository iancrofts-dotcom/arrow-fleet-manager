import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../models/calendar_event.dart';

class VehicleCalendarMapper {
  const VehicleCalendarMapper();

  List<CalendarEvent> map(
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
            type: CalendarEventType.vehicle,
            icon: Icons.directions_car,
            color: Colors.blue,
          ),
        );
      }

      if (vehicle.serviceDue != null) {
        events.add(
          CalendarEvent(
            title: 'Service Due',
            subtitle: vehicle.registration,
            date: vehicle.serviceDue!,
            type: CalendarEventType.vehicle,
            icon: Icons.build,
            color: Colors.orange,
          ),
        );
      }
    }

    return events;
  }
}