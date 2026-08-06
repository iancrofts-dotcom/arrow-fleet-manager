import 'package:arrow_fleet_manager/features/workshop/models/workshop_inspection.dart';
import 'inspection_checklist_item.dart';
import 'repair_job.dart';

/// Temporary model used while completing the Workshop Inspection Wizard.
///
/// Nothing is written to the database until the user finishes
/// the final step of the wizard.
class InspectionWizardData {
  // =============================
  // Vehicle
  // =============================

  int? vehicleId;
  String? registration;
  String? fleetNumber;
  int? mileage;

  // =============================
  // Inspection
  // =============================

  WorkshopInspectionType? inspectionType;

  int? technicianId;
  String? technicianName;

  String? workshopManager;

// =============================
// Inspection Data
// =============================

List<InspectionChecklistItem> checklistItems = [];

List<RepairJob> repairJobs = [];

  // =============================
  // Checklist Summary
  // =============================

  int inspectionScore = 0;
  int criticalFailures = 0;
  int advisories = 0;
  int repairsRequired = 0;

  double labourHours = 0;
  double estimatedCost = 0;

  // =============================
  // Results
  // =============================

  VehicleWorkshopStatus vehicleStatus =
      VehicleWorkshopStatus.roadworthy;

  InspectionResult overallResult =
      InspectionResult.pending;

  // =============================
  // Notes
  // =============================

  String notes = '';

  // =============================
  // Sign Off
  // =============================

  String? technicianSignature;
  String? managerSignature;

  // =============================
  // Helpers
  // =============================

  bool get hasVehicle => vehicleId != null;

  bool get hasMileage =>
      mileage != null && mileage! > 0;

  bool get hasInspectionType =>
      inspectionType != null;

  bool get hasTechnician =>
      technicianName != null &&
      technicianName!.isNotEmpty;

  bool get canContinueFromStep1 =>
      hasVehicle &&
      hasMileage &&
      hasInspectionType &&
      hasTechnician;

  void reset() {
    vehicleId = null;
    registration = null;
    fleetNumber = null;
    mileage = null;

    inspectionType = null;

    technicianId = null;
    technicianName = null;

    workshopManager = null;
    checklistItems.clear();
    repairJobs.clear();

    inspectionScore = 0;
    criticalFailures = 0;
    advisories = 0;
    repairsRequired = 0;

    labourHours = 0;
    estimatedCost = 0;

    vehicleStatus = VehicleWorkshopStatus.roadworthy;
    overallResult = InspectionResult.pending;

    notes = '';

    technicianSignature = null;
    managerSignature = null;
  }
}