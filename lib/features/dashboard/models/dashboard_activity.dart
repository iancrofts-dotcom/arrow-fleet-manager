class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final DashboardActivityType type;

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  String get relativeDate {
    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final activityDay = DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today.difference(activityDay).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Yesterday';
    }

    if (difference < 7) {
      return '$difference days ago';
    }

    return formattedDate;
  }

  DashboardActivity copyWith({
    String? title,
    String? subtitle,
    DateTime? date,
    DashboardActivityType? type,
  }) {
    return DashboardActivity(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      type: type ?? this.type,
    );
  }
}

enum DashboardActivityType {
  vehicle,
  driver,
  assignment,
  maintenance,
  compliance,
}