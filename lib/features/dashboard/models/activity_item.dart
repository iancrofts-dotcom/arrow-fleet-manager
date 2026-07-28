enum ActivityType {
  vehicle,
  driver,
  maintenance,
  inspection,
  compliance,
  system,
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
  });

  final String id;
  final String title;
  final String description;
  final ActivityType type;
  final DateTime timestamp;

  ActivityItem copyWith({
    String? id,
    String? title,
    String? description,
    ActivityType? type,
    DateTime? timestamp,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}