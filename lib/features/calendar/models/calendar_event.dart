import 'package:flutter/material.dart';

enum CalendarEventType {
  vehicle,
  maintenance,
  document,
  licence,
  cpc,
  medical,
  dbs,
  taxiLicence,
}

class CalendarEvent {
  const CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    required this.icon,
    required this.color,
    this.source,
    this.vehicleId,
    this.driverId,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final CalendarEventType type;

  final IconData icon;
  final Color color;

  final Object? source;

  /// Persisted Vehicle identity for events that can open Vehicle Details.
  final int? vehicleId;

  /// Persisted Driver identity for compliance events that can open details.
  final int? driverId;

  bool get isActionable => vehicleId != null || driverId != null;
}
