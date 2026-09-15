class BackendWorkshopRepairJob {
  const BackendWorkshopRepairJob({
    required this.id,
    required this.jobNumber,
    required this.inspectionId,
    required this.vehicleId,
    required this.vehicleRegistration,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.technicianName,
    required this.partsRequired,
    required this.estimatedHours,
    required this.actualHours,
    required this.estimatedCost,
    required this.actualCost,
    required this.roadworthy,
    required this.createdAt,
    this.legacyId,
    this.inspectionItemId,
    this.technicianProfileId,
    this.startedAt,
    this.completedAt,
    this.workNotes = '',
    this.partsNotes = '',
    this.signedOffBy,
    this.signedOffName = '',
    this.signedOffAt,
    this.technicianMileage,
  });

  final String id;
  final int? legacyId;
  final String jobNumber;
  final String inspectionId;
  final String? inspectionItemId;
  final String vehicleId;
  final String vehicleRegistration;
  final String title;
  final String description;
  final String priority;
  final String status;
  final String? technicianProfileId;
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
  final String workNotes;
  final String partsNotes;
  final String? signedOffBy;
  final String signedOffName;
  final DateTime? signedOffAt;
  final int? technicianMileage;

  bool get isOutstanding => status != 'completed' && status != 'cancelled';

  factory BackendWorkshopRepairJob.fromJson(Map<String, dynamic> json) {
    return BackendWorkshopRepairJob(
      id: json['id'] as String,
      legacyId: json['legacy_id'] as int?,
      jobNumber: json['job_number'] as String,
      inspectionId: json['inspection_id'] as String,
      inspectionItemId: json['inspection_item_id'] as String?,
      vehicleId: json['vehicle_id'] as String,
      vehicleRegistration: json['vehicle_registration'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String,
      status: json['status'] as String,
      technicianProfileId: json['technician_profile_id'] as String?,
      technicianName: json['technician_name'] as String? ?? '',
      partsRequired: json['parts_required'] as bool? ?? false,
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble() ?? 0,
      actualHours: (json['actual_hours'] as num?)?.toDouble() ?? 0,
      estimatedCost: (json['estimated_cost'] as num?)?.toDouble() ?? 0,
      actualCost: (json['actual_cost'] as num?)?.toDouble() ?? 0,
      roadworthy: json['roadworthy'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      workNotes: json['work_notes'] as String? ?? '',
      partsNotes: json['parts_notes'] as String? ?? '',
      signedOffBy: json['signed_off_by'] as String?,
      signedOffName: json['signed_off_name'] as String? ?? '',
      signedOffAt: json['signed_off_at'] == null
          ? null
          : DateTime.parse(json['signed_off_at'] as String),
      technicianMileage: (json['technician_mileage'] as num?)?.toInt(),
    );
  }
}
