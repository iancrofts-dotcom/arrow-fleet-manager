class MaintenanceRecord {
  final int? id;
  final int vehicleId;
  final String title;
  final String description;
  final DateTime dueDate;
  final DateTime? completedDate;
  final double estimatedCost;
  final double? actualCost;
  final bool completed;

  const MaintenanceRecord({
    this.id,
    required this.vehicleId,
    required this.title,
    required this.description,
    required this.dueDate,
    this.completedDate,
    required this.estimatedCost,
    this.actualCost,
    this.completed = false,
  });

  MaintenanceRecord copyWith({
    int? id,
    int? vehicleId,
    String? title,
    String? description,
    DateTime? dueDate,
    DateTime? completedDate,
    double? estimatedCost,
    double? actualCost,
    bool? completed,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completedDate: completedDate ?? this.completedDate,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      completed: completed ?? this.completed,
    );
  }

  bool get isOverdue =>
      !completed && dueDate.isBefore(DateTime.now());

  int get daysRemaining =>
      dueDate.difference(DateTime.now()).inDays;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'title': title,
      'description': description,
      'due_date': dueDate.millisecondsSinceEpoch,
      'completed_date':
          completedDate?.millisecondsSinceEpoch,
      'estimated_cost': estimatedCost,
      'actual_cost': actualCost,
      'completed': completed ? 1 : 0,
    };
  }

  factory MaintenanceRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    return MaintenanceRecord(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      dueDate: DateTime.fromMillisecondsSinceEpoch(
        map['due_date'] as int,
      ),
      completedDate: map['completed_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              map['completed_date'] as int,
            )
          : null,
      estimatedCost:
          (map['estimated_cost'] as num).toDouble(),
      actualCost: map['actual_cost'] != null
          ? (map['actual_cost'] as num).toDouble()
          : null,
      completed: (map['completed'] ?? 0) == 1,
    );
  }

  @override
  String toString() {
    return 'MaintenanceRecord(id: $id, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MaintenanceRecord &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.title == title &&
        other.description == description &&
        other.dueDate == dueDate &&
        other.completedDate == completedDate &&
        other.estimatedCost == estimatedCost &&
        other.actualCost == actualCost &&
        other.completed == completed;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        title,
        description,
        dueDate,
        completedDate,
        estimatedCost,
        actualCost,
        completed,
      );
}