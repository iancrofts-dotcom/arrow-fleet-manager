import 'package:flutter/material.dart';

import '../../documents/models/fleet_document.dart';
import '../../drivers/models/driver.dart';
import '../../vehicles/models/vehicle.dart';
import '../models/calendar_event.dart';

class DocumentCalendarMapper {
  const DocumentCalendarMapper();

  List<CalendarEvent> map({
    required List<FleetDocument> documents,
    required Map<int, Vehicle> vehicles,
    required Map<int, Driver> drivers,
  }) {
    final events = <CalendarEvent>[];

    for (final document in documents) {
      String subtitle = '';

      if (document.vehicleId != null) {
        subtitle = vehicles[document.vehicleId]?.registration ??
            'Unknown Vehicle';
      } else if (document.driverId != null) {
        final driver = drivers[document.driverId];

        subtitle = driver == null
            ? 'Unknown Driver'
            : '${driver.firstName} ${driver.lastName}';
      }

      events.add(
        CalendarEvent(
          title: document.title,
          subtitle: subtitle,
          date: document.expiryDate,
          type: CalendarEventType.document,
          icon: _icon(document.category),
          color: document.isExpired
              ? Colors.red
              : document.isDueSoon
                  ? Colors.orange
                  : Colors.blue,

                  source: document,
        ),
      );
    }

    return events;
  }

  IconData _icon(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.insurance:
        return Icons.security;

      case DocumentCategory.mot:
        return Icons.directions_car;

      case DocumentCategory.service:
        return Icons.build;

      case DocumentCategory.inspection:
        return Icons.assignment;

      case DocumentCategory.licence:
        return Icons.badge;

      case DocumentCategory.cpc:
        return Icons.school;

      case DocumentCategory.medical:
        return Icons.medical_services;

      case DocumentCategory.v5:
        return Icons.description;

      case DocumentCategory.policy:
        return Icons.policy;

      case DocumentCategory.other:
        return Icons.insert_drive_file;
    }
  }
}