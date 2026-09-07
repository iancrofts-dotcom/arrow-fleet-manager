import 'package:flutter/material.dart';

import '../../vehicles/models/vehicle.dart';
import '../models/calendar_event.dart';

class VehicleCalendarMapper {
  const VehicleCalendarMapper();

  List<CalendarEvent> map(List<Vehicle> vehicles) {
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
            source: vehicle,
            vehicleId: vehicle.id,
          ),
        );
      }

      if (vehicle.taxiPlateExpiry != null) {
        events.add(
          CalendarEvent(
            title: 'Taxi Plate Expiry',
            subtitle: vehicle.registration,
            date: vehicle.taxiPlateExpiry!,
            type: CalendarEventType.vehicle,
            icon: Icons.local_taxi_outlined,
            color: Colors.orange,
            source: vehicle,
            vehicleId: vehicle.id,
          ),
        );
      }

      if (vehicle.serviceDue != null) {
        events.add(
          CalendarEvent(
            title: 'Service Due',
            subtitle: vehicle.registration,
            date: vehicle.serviceDue!,
            type: CalendarEventType.maintenance,
            icon: Icons.build,
            color: Colors.orange,
            source: vehicle,
            vehicleId: vehicle.id,
          ),
        );
      }
    }

    return events;
  }
}
