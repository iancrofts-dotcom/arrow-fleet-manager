import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';

import 'inspection_checklist_item.dart';
import 'repair_job.dart';

/// ============================================================================
/// INSPECTION WIZARD DATA
/// ============================================================================
///
/// Temporary model used while completing the Workshop Inspection Wizard.
///
/// Nothing is written to the database until the user finishes
/// the final step of the wizard.
/// ============================================================================
class InspectionWizardData {
  // ==========================================================================
  // Vehicle
  // ==========================================================================

  int? vehicleId;
  String? registration;
  String? fleetNumber;
  int? mileage;

  // ==========================================================================
  // Inspection
  // ==========================================================================

  String inspectionNumber = '';

  WorkshopInspectionType? inspectionType;

  DateTime dateStarted = DateTime.now();

  DateTime createdAt = DateTime.now();

  DateTime updatedAt = DateTime.now();

  // ==========================================================================
  // Personnel
  // ==========================================================================

  int? technicianId;

  String? technicianName;

  String? technician;

  String? workshopManager;

  String? finalNotes;

  // ==========================================================================
  // Inspection Data
  // ==========================================================================

  List<InspectionChecklistItem> checklistItems = [];

  List<RepairJob> repairJobs = [];

  // ==========================================================================
  // Inspection Summary
  // ==========================================================================

  int inspectionScore = 0;

  int criticalFailures = 0;

  int advisories = 0;

  int repairsRequired = 0;

  double labourHours = 0;

  double totalCost = 0;

  // ==========================================================================
  // Results
  // ==========================================================================

  VehicleWorkshopStatus vehicleStatus =
      VehicleWorkshopStatus.roadworthy;

  InspectionResult overallResult =
      InspectionResult.pending;

  // ==========================================================================
  // Notes
  // ==========================================================================

  String notes = '';

  // ==========================================================================
  // Signatures
  // ==========================================================================

  String? technicianSignature;

  String? managerSignature;

  // ==========================================================================
  // Helpers
  // ==========================================================================

  bool get hasVehicle => vehicleId != null;

  bool get hasMileage =>
      mileage != null && mileage! > 0;

  bool get hasInspectionType =>
      inspectionType != null;

  bool get hasTechnician =>
      technicianName != null &&
      technicianName!.trim().isNotEmpty;

  bool get canContinueFromStep1 =>
      hasVehicle &&
      hasMileage &&
      hasInspectionType &&
      hasTechnician;

  // ==========================================================================
  // Reset
  // ==========================================================================

  void reset() {
    // Vehicle
    vehicleId = null;
    registration = null;
    fleetNumber = null;
    mileage = null;

    // Inspection
    inspectionNumber = '';
    inspectionType = null;
    dateStarted = DateTime.now();
    createdAt = DateTime.now();
    updatedAt = DateTime.now();

    // Personnel
    technicianId = null;
    technicianName = null;
    technician = null;
    workshopManager = null;
    finalNotes = null;

    // Inspection Data
    checklistItems.clear();
    repairJobs.clear();

    // Summary
    inspectionScore = 0;
    criticalFailures = 0;
    advisories = 0;
    repairsRequired = 0;

    labourHours = 0;
    totalCost = 0;

    // Results
    vehicleStatus =
        VehicleWorkshopStatus.roadworthy;

    overallResult =
        InspectionResult.pending;

    // Notes
    notes = '';

    // Signatures
    technicianSignature = null;
    managerSignature = null;
  }
}