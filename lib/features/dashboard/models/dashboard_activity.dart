class DashboardActivity {
  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.type,
    this.route,
    this.entityId,
    this.driverId,
    this.vehicleId,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final DashboardActivityType type;

  /// Optional dashboard navigation route
  final String? route;

  /// Optional ID of the related record
  final String? entityId;

  /// Persisted Driver identity associated with this activity, when applicable.
  final int? driverId;

  /// Persisted Vehicle identity associated with this activity, when applicable.
  final int? vehicleId;

  String get formattedDate {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;

    return '$day/$month/$year';
  }

  String get relativeDate {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final activityDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(activityDay).inDays;

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
    String? route,
    String? entityId,
    int? driverId,
    int? vehicleId,
  }) {
    return DashboardActivity(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      type: type ?? this.type,
      route: route ?? this.route,
      entityId: entityId ?? this.entityId,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
    );
  }
}

enum DashboardActivityType {
  vehicle,
  driver,
  assignment,
  maintenance,
  compliance,
  dailyCheck,
}
