class DriverAssignment {
  final int? id;
  final int driverId;
  final int vehicleId;

  final DateTime startDate;
  final DateTime? endDate;

  final bool isActive;
  final String? notes;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DriverAssignment({
    this.id,
    required this.driverId,
    required this.vehicleId,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  DriverAssignment copyWith({
    int? id,
    int? driverId,
    int? vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DriverAssignment(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      vehicleId: vehicleId ?? this.vehicleId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DriverAssignment.fromMap(Map<String, dynamic> map) {
    return DriverAssignment(
      id: map['id'] as int?,
      driverId: map['driver_id'] as int,
      vehicleId: map['vehicle_id'] as int,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isActive: (map['active'] as int) == 1,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'vehicle_id': vehicleId,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'active': isActive ? 1 : 0,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}