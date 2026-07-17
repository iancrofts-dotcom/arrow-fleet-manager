import 'calendar_event.dart';

enum CalendarGroup {
  overdue,
  thisWeek,
  next30Days,
  future,
}

extension CalendarGrouping on List<CalendarEvent> {
  Map<CalendarGroup, List<CalendarEvent>> grouped() {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final groups = <CalendarGroup, List<CalendarEvent>>{
      CalendarGroup.overdue: [],
      CalendarGroup.thisWeek: [],
      CalendarGroup.next30Days: [],
      CalendarGroup.future: [],
    };

    for (final event in this) {
      final date = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      final days = date.difference(today).inDays;

      if (days < 0) {
        groups[CalendarGroup.overdue]!.add(event);
      } else if (days <= 7) {
        groups[CalendarGroup.thisWeek]!.add(event);
      } else if (days <= 30) {
        groups[CalendarGroup.next30Days]!.add(event);
      } else {
        groups[CalendarGroup.future]!.add(event);
      }
    }

    return groups;
  }
}

extension CalendarGroupExtensions on CalendarGroup {
  String get title {
    switch (this) {
      case CalendarGroup.overdue:
        return 'Overdue';

      case CalendarGroup.thisWeek:
        return 'This Week';

      case CalendarGroup.next30Days:
        return 'Next 30 Days';

      case CalendarGroup.future:
        return 'Future';
    }
  }
}