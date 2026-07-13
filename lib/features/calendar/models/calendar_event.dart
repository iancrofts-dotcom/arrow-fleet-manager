enum CalendarEventType {
  mot,
  service,
  inspection,
  overdue,
}

class CalendarEvent {
  final String title;
  final String subtitle;
  final DateTime date;
  final CalendarEventType type;

  const CalendarEvent({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
  });
}