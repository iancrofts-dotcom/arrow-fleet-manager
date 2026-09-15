class BackendDriverAssignment {
  const BackendDriverAssignment({
    required this.id,
    this.legacyId,
    required this.driverId,
    required this.vehicleId,
    required this.assignedFrom,
    this.assignedTo,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final int? legacyId;
  final String driverId;
  final String vehicleId;
  final DateTime assignedFrom;
  final DateTime? assignedTo;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  factory BackendDriverAssignment.fromJson(Map<String, dynamic> json) =>
      BackendDriverAssignment(
        id: _assignmentUuid(json['id'], 'id'),
        legacyId: json['legacy_id'] as int?,
        driverId: _assignmentUuid(json['driver_id'], 'driver_id'),
        vehicleId: _assignmentUuid(json['vehicle_id'], 'vehicle_id'),
        assignedFrom: DateTime.parse(json['assigned_from'] as String),
        assignedTo: json['assigned_to'] == null
            ? null
            : DateTime.parse(json['assigned_to'] as String),
        isActive: json['is_active'] as bool,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class BackendDriverAssignmentWrite {
  const BackendDriverAssignmentWrite({
    this.legacyId,
    required this.driverId,
    required this.vehicleId,
    required this.assignedFrom,
    this.assignedTo,
    this.isActive = true,
  });
  final int? legacyId;
  final String driverId;
  final String vehicleId;
  final DateTime assignedFrom;
  final DateTime? assignedTo;
  final bool isActive;
  Map<String, dynamic> toInsertJson() => {
    'legacy_id': legacyId,
    'driver_id': driverId,
    'vehicle_id': vehicleId,
    'assigned_from': assignedFrom.toUtc().toIso8601String(),
    'assigned_to': assignedTo?.toUtc().toIso8601String(),
    'is_active': isActive,
  };
  Map<String, dynamic> toUpdateJson() => {
    'assigned_to': assignedTo?.toUtc().toIso8601String(),
    'is_active': isActive,
  };
}

String _assignmentUuid(Object? input, String field) {
  final value = (input as String).toLowerCase();
  if (!RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  ).hasMatch(value)) {
    throw FormatException('Invalid $field.');
  }
  return value;
}
