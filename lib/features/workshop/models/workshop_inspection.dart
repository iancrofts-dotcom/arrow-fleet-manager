import 'dart:convert';

/// ============================================================================
/// WORKSHOP INSPECTION STATUS
/// ============================================================================

enum WorkshopInspectionStatus {
  draft,
  inProgress,
  awaitingRepair,
  completed,
  signedOff,
  cancelled,
}

/// ============================================================================
/// INSPECTION RESULT
/// ============================================================================

enum InspectionResult {
  pending,
  pass,
  fail,
  advisory,
}

/// ============================================================================
/// VEHICLE STATUS
/// ============================================================================

enum VehicleWorkshopStatus {
  roadworthy,
  notRoadworthy,
  awaitingRepair,
  underRepair,
  released,
}

/// ============================================================================
/// INSPECTION TYPE
/// ============================================================================

enum WorkshopInspectionType {
  scheduledService,
  defectInspection,
  annualInspection,
  motPreparation,
  repairInspection,
  returnToService,
  driverDailyInspection,
}

/// ============================================================================
/// WORKSHOP INSPECTION MODEL
/// ============================================================================

class WorkshopInspection {
  final int? id;

  final String inspectionNumber;

  final int vehicleId;
  final String registration;
  final String fleetNumber;

  final int? technicianId;
  final String technicianName;

  final int? driverId;
  final String? driverName;

  final String? workshopManager;

  final WorkshopInspectionType inspectionType;

  final WorkshopInspectionStatus status;

  final VehicleWorkshopStatus vehicleStatus;

  final DateTime dateStarted;
  final DateTime? dateCompleted;

  final int mileage;

  final InspectionResult overallResult;

  final int inspectionScore;

  final int criticalFailures;

  final int advisories;

  final int repairsRequired;

  final double labourHours;

  final double totalCost;

  final String notes;

  final String? technicianSignature;

  final String? managerSignature;

  final DateTime createdAt;

  final DateTime updatedAt;

  const WorkshopInspection({
    this.id,
    required this.inspectionNumber,
    required this.vehicleId,
    required this.registration,
    required this.fleetNumber,
    this.technicianId,
    required this.technicianName,
    this.driverId,
    this.driverName,
    this.workshopManager,
    required this.inspectionType,
    required this.status,
    required this.vehicleStatus,
    required this.dateStarted,
    this.dateCompleted,
    required this.mileage,
    required this.overallResult,
    required this.inspectionScore,
    required this.criticalFailures,
    required this.advisories,
    required this.repairsRequired,
    required this.labourHours,
    required this.totalCost,
    required this.notes,
    this.technicianSignature,
    this.managerSignature,
    required this.createdAt,
    required this.updatedAt,
  });

  WorkshopInspection copyWith({
    int? id,
    String? inspectionNumber,
    int? vehicleId,
    String? registration,
    String? fleetNumber,
    int? technicianId,
    String? technicianName,
    int? driverId,
    String? driverName,
    String? workshopManager,
    WorkshopInspectionType? inspectionType,
    WorkshopInspectionStatus? status,
    VehicleWorkshopStatus? vehicleStatus,
    DateTime? dateStarted,
    DateTime? dateCompleted,
    int? mileage,
    InspectionResult? overallResult,
    int? inspectionScore,
    int? criticalFailures,
    int? advisories,
    int? repairsRequired,
    double? labourHours,
    double? totalCost,
    String? notes,
    String? technicianSignature,
    String? managerSignature,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WorkshopInspection(
      id: id ?? this.id,
      inspectionNumber: inspectionNumber ?? this.inspectionNumber,
      vehicleId: vehicleId ?? this.vehicleId,
      registration: registration ?? this.registration,
      fleetNumber: fleetNumber ?? this.fleetNumber,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      workshopManager: workshopManager ?? this.workshopManager,
      inspectionType: inspectionType ?? this.inspectionType,
      status: status ?? this.status,
      vehicleStatus: vehicleStatus ?? this.vehicleStatus,
      dateStarted: dateStarted ?? this.dateStarted,
      dateCompleted: dateCompleted ?? this.dateCompleted,
      mileage: mileage ?? this.mileage,
      overallResult: overallResult ?? this.overallResult,
      inspectionScore: inspectionScore ?? this.inspectionScore,
      criticalFailures: criticalFailures ?? this.criticalFailures,
      advisories: advisories ?? this.advisories,
      repairsRequired: repairsRequired ?? this.repairsRequired,
      labourHours: labourHours ?? this.labourHours,
      totalCost: totalCost ?? this.totalCost,
      notes: notes ?? this.notes,
      technicianSignature:
          technicianSignature ?? this.technicianSignature,
      managerSignature: managerSignature ?? this.managerSignature,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'inspectionNumber': inspectionNumber,
      'vehicleId': vehicleId,
      'registration': registration,
      'fleetNumber': fleetNumber,
      'technicianId': technicianId,
      'technicianName': technicianName,
      'driverId': driverId,
      'driverName': driverName,
      'workshopManager': workshopManager,
      'inspectionType': inspectionType.name,
      'status': status.name,
      'vehicleStatus': vehicleStatus.name,
      'dateStarted': dateStarted.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
      'mileage': mileage,
      'overallResult': overallResult.name,
      'inspectionScore': inspectionScore,
      'criticalFailures': criticalFailures,
      'advisories': advisories,
      'repairsRequired': repairsRequired,
      'labourHours': labourHours,
      'totalCost': totalCost,
      'notes': notes,
      'technicianSignature': technicianSignature,
      'managerSignature': managerSignature,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory WorkshopInspection.fromMap(Map<String, dynamic> map) {
    return WorkshopInspection(
      id: map['id'],
      inspectionNumber: map['inspectionNumber'],
      vehicleId: map['vehicleId'],
      registration: map['registration'],
      fleetNumber: map['fleetNumber'],
      technicianId: map['technicianId'],
      technicianName: map['technicianName'],
      driverId: map['driverId'],
      driverName: map['driverName'],
      workshopManager: map['workshopManager'],
      inspectionType: WorkshopInspectionType.values.firstWhere(
        (e) => e.name == map['inspectionType'],
      ),
      status: WorkshopInspectionStatus.values.firstWhere(
        (e) => e.name == map['status'],
      ),
      vehicleStatus: VehicleWorkshopStatus.values.firstWhere(
        (e) => e.name == map['vehicleStatus'],
      ),
      dateStarted: DateTime.parse(map['dateStarted']),
      dateCompleted: map['dateCompleted'] != null
          ? DateTime.parse(map['dateCompleted'])
          : null,
      mileage: map['mileage'],
      overallResult: InspectionResult.values.firstWhere(
        (e) => e.name == map['overallResult'],
      ),
      inspectionScore: map['inspectionScore'],
      criticalFailures: map['criticalFailures'],
      advisories: map['advisories'],
      repairsRequired: map['repairsRequired'],
      labourHours: (map['labourHours'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      notes: map['notes'] ?? '',
      technicianSignature: map['technicianSignature'],
      managerSignature: map['managerSignature'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory WorkshopInspection.fromJson(String source) =>
      WorkshopInspection.fromMap(jsonDecode(source));
}
