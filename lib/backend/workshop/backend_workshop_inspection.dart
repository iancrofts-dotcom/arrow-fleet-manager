class BackendWorkshopInspection {
  const BackendWorkshopInspection({
    required this.id,
    required this.inspectionNumber,
    required this.vehicleId,
    required this.registration,
    required this.fleetNumber,
    required this.technicianName,
    required this.inspectionType,
    required this.status,
    required this.vehicleStatus,
    required this.dateStarted,
    required this.mileage,
    required this.overallResult,
    required this.inspectionScore,
    required this.criticalFailures,
    required this.advisories,
    required this.repairsRequired,
    required this.labourHours,
    required this.totalCost,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.legacyId,
    this.templateName,
    this.technicianProfileId,
    this.driverId,
    this.driverName,
    this.workshopManager,
    this.dateCompleted,
  });

  final String id;
  final int? legacyId;
  final String inspectionNumber;
  final String vehicleId;
  final String registration;
  final String fleetNumber;
  final String? templateName;
  final String? technicianProfileId;
  final String technicianName;
  final String? driverId;
  final String? driverName;
  final String? workshopManager;
  final String inspectionType;
  final String status;
  final String vehicleStatus;
  final DateTime dateStarted;
  final DateTime? dateCompleted;
  final int mileage;
  final String overallResult;
  final int inspectionScore;
  final int criticalFailures;
  final int advisories;
  final int repairsRequired;
  final double labourHours;
  final double totalCost;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen =>
      const {'draft', 'inProgress', 'awaitingRepair'}.contains(status);

  bool get isCompleted => status == 'completed' || status == 'signedOff';

  factory BackendWorkshopInspection.fromJson(Map<String, dynamic> json) {
    return BackendWorkshopInspection(
      id: json['id'] as String,
      legacyId: json['legacy_id'] as int?,
      inspectionNumber: json['inspection_number'] as String,
      vehicleId: json['vehicle_id'] as String,
      registration: json['registration'] as String,
      fleetNumber: (json['fleet_number'] as String?) ?? '',
      templateName: json['template_name'] as String?,
      technicianProfileId: json['technician_profile_id'] as String?,
      technicianName: (json['technician_name'] as String?) ?? '',
      driverId: json['driver_id'] as String?,
      driverName: json['driver_name'] as String?,
      workshopManager: json['workshop_manager'] as String?,
      inspectionType: json['inspection_type'] as String,
      status: json['status'] as String,
      vehicleStatus: json['vehicle_status'] as String,
      dateStarted: DateTime.parse(json['date_started'] as String),
      dateCompleted: json['date_completed'] == null
          ? null
          : DateTime.parse(json['date_completed'] as String),
      mileage: (json['mileage'] as num).toInt(),
      overallResult: json['overall_result'] as String,
      inspectionScore: (json['inspection_score'] as num?)?.toInt() ?? 0,
      criticalFailures: (json['critical_failures'] as num?)?.toInt() ?? 0,
      advisories: (json['advisories'] as num?)?.toInt() ?? 0,
      repairsRequired: (json['repairs_required'] as num?)?.toInt() ?? 0,
      labourHours: (json['labour_hours'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      notes: (json['notes'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
