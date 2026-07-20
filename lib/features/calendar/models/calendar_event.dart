import 'package:flutter/material.dart';

enum CalendarEventType {
  vehicle,
  maintenance,
  document,
  licence,
  cpc,
  medical,
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
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final CalendarEventType type;

  final IconData icon;
  final Color color;

  final Object? source;
}