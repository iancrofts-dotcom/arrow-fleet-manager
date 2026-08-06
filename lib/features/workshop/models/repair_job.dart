import 'dart:convert';

/// ============================================================================
/// REPAIR JOB STATUS
/// ============================================================================

enum RepairJobStatus {
  open,
  assigned,
  inProgress,
  awaitingParts,
  awaitingInspection,
  completed,
  cancelled,
}

/// ============================================================================
/// REPAIR PRIORITY
/// ============================================================================

enum RepairPriority {
  low,
  medium,
  high,
  critical,
}

/// ============================================================================
/// REPAIR JOB
/// ============================================================================

class RepairJob {
  final int? id;

  final String jobNumber;

  final int inspectionId;

  final int inspectionItemId;

  final int vehicleId;

  final String vehicleRegistration;

  final String title;

  final String description;

  final RepairPriority priority;

  final RepairJobStatus status;

  final int? technicianId;

  final String technicianName;

  final bool partsRequired;

  final double estimatedHours;

  final double actualHours;

  final double estimatedCost;

  final double actualCost;

  final bool roadworthy;

  final DateTime createdAt;

  final DateTime? startedAt;

  final DateTime? completedAt;

  const RepairJob({
    this.id,
    required this.jobNumber,
    required this.inspectionId,
    required this.inspectionItemId,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.title,
    required this.description,
    this.priority = RepairPriority.medium,
    this.status = RepairJobStatus.open,
    this.technicianId,
    this.technicianName = '',
    this.partsRequired = false,
    this.estimatedHours = 0,
    this.actualHours = 0,
    this.estimatedCost = 0,
    this.actualCost = 0,
    this.roadworthy = false,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  RepairJob copyWith({
    int? id,
    String? jobNumber,
    int? inspectionId,
    int? inspectionItemId,
    int? vehicleId,
    String? vehicleRegistration,
    String? title,
    String? description,
    RepairPriority? priority,
    RepairJobStatus? status,
    int? technicianId,
    String? technicianName,
    bool? partsRequired,
    double? estimatedHours,
    double? actualHours,
    double? estimatedCost,
    double? actualCost,
    bool? roadworthy,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return RepairJob(
      id: id ?? this.id,
      jobNumber: jobNumber ?? this.jobNumber,
      inspectionId: inspectionId ?? this.inspectionId,
      inspectionItemId: inspectionItemId ?? this.inspectionItemId,
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleRegistration:
          vehicleRegistration ?? this.vehicleRegistration,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      partsRequired: partsRequired ?? this.partsRequired,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      roadworthy: roadworthy ?? this.roadworthy,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'jobNumber': jobNumber,
      'inspectionId': inspectionId,
      'inspectionItemId': inspectionItemId,
      'vehicleId': vehicleId,
      'vehicleRegistration': vehicleRegistration,
      'title': title,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'partsRequired': partsRequired ? 1 : 0,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'roadworthy': roadworthy ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory RepairJob.fromMap(Map<String, dynamic> map) {
    return RepairJob(
      id: map['id'],
      jobNumber: map['jobNumber'],
      inspectionId: map['inspectionId'],
      inspectionItemId: map['inspectionItemId'],
      vehicleId: map['vehicleId'],
      vehicleRegistration: map['vehicleRegistration'],
      title: map['title'],
      description: map['description'],
      priority: RepairPriority.values.firstWhere(
        (e) => e.name == map['priority'],
      ),
      status: RepairJobStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      technicianId: map['technicianId'],
      technicianName: map['technicianName'] ?? '',
      partsRequired: map['partsRequired'] == 1,
      estimatedHours: (map['estimatedHours'] as num).toDouble(),
      actualHours: (map['actualHours'] as num).toDouble(),
      estimatedCost: (map['estimatedCost'] as num).toDouble(),
      actualCost: (map['actualCost'] as num).toDouble(),
      roadworthy: map['roadworthy'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      startedAt: map['startedAt'] != null
          ? DateTime.parse(map['startedAt'])
          : null,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RepairJob.fromJson(String source) =>
      RepairJob.fromMap(jsonDecode(source));
}