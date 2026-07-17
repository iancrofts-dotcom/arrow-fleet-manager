import 'package:flutter/material.dart';

import '../../drivers/models/driver.dart';
import '../../drivers/models/driver_compliance.dart';
import '../models/calendar_event.dart';

class ComplianceCalendarMapper {
  const ComplianceCalendarMapper();

  List<CalendarEvent> map({
    required List<DriverCompliance> records,
    required Map<int, Driver> drivers,
  }) {
    final events = <CalendarEvent>[];

    for (final record in records) {
      final driver = drivers[record.driverId];

      final name = driver == null
          ? 'Unknown Driver'
          : '${driver.firstName} ${driver.lastName}';

      events.addAll([
        CalendarEvent(
          title: 'Driving Licence',
          subtitle: name,
          date: record.licenceExpiry,
          type: CalendarEventType.licence,
          icon: Icons.badge,
          color: record.licenceExpired
              ? Colors.red
              : Colors.orange,
        ),
        CalendarEvent(
          title: 'CPC Renewal',
          subtitle: name,
          date: record.cpcExpiry,
          type: CalendarEventType.cpc,
          icon: Icons.school,
          color: record.cpcExpired
              ? Colors.red
              : Colors.orange,
        ),
        CalendarEvent(
          title: 'Medical Renewal',
          subtitle: name,
          date: record.medicalExpiry,
          type: CalendarEventType.medical,
          icon: Icons.medical_services,
          color: record.medicalExpired
              ? Colors.red
              : Colors.orange,
        ),
      ]);
    }

    return events;
  }
}