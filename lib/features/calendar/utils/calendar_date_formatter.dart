class CalendarDateFormatter {
  const CalendarDateFormatter._();

  static String format(DateTime date) {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final target = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final days = target.difference(today).inDays;

    switch (days) {
      case 0:
        return 'Today';

      case 1:
        return 'Tomorrow';
    }

    if (days > 1 && days <= 6) {
      return _weekday(target.weekday);
    }

    if (days > 6 && days <= 13) {
      return 'Next ${_weekday(target.weekday)}';
    }

    if (target.year == today.year) {
      return '${target.day} ${_month(target.month)}';
    }

    return '${target.day} ${_month(target.month)} ${target.year}';
  }

  static String _weekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';

      case DateTime.tuesday:
        return 'Tuesday';

      case DateTime.wednesday:
        return 'Wednesday';

      case DateTime.thursday:
        return 'Thursday';

      case DateTime.friday:
        return 'Friday';

      case DateTime.saturday:
        return 'Saturday';

      case DateTime.sunday:
        return 'Sunday';

      default:
        return '';
    }
  }

  static String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }
}