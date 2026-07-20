import 'package:flutter/material.dart';

import '../../maintenance/models/maintenance_record.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/calendar_event.dart';

class MaintenanceCalendarMapper {
  const MaintenanceCalendarMapper();

  List<CalendarEvent> map(
    List<MaintenanceRecord> records,
    Map<int, Vehicle> vehicles,
  ) {
    final events = <CalendarEvent>[];

    for (final record in records) {
      if (record.completed) {
        continue;
      }

      final vehicle = vehicles[record.vehicleId];

      events.add(
        CalendarEvent(
          title: record.title,
          subtitle: vehicle?.registration ?? 'Unknown Vehicle',
          date: record.dueDate,
          type: CalendarEventType.maintenance,
          icon: record.isOverdue
              ? Icons.warning
              : Icons.build_circle,
          color: record.isOverdue
              ? Colors.red
              : Colors.orange,

              source: record,
        ),
      );
    }

    return events;
  }
}