import '../../models/inspection_wizard_data.dart';
import '../../models/workshop_inspection.dart';

class InspectionMapper {
  const InspectionMapper();

  WorkshopInspection map(InspectionWizardData data) {
    return WorkshopInspection(
      inspectionNumber: data.inspectionNumber,

      vehicleId: data.vehicleId ?? 0,
      registration: data.registration ?? '',
      fleetNumber: data.fleetNumber ?? '',

      technicianId: data.technicianId,
      technicianName: data.technicianName ??
          data.technician ??
          '',

      workshopManager: data.workshopManager,

      inspectionType:
          data.inspectionType ??
              WorkshopInspectionType.defectInspection,

      status: data.repairsRequired > 0
          ? WorkshopInspectionStatus.awaitingRepair
          : WorkshopInspectionStatus.completed,

      vehicleStatus:
          data.vehicleStatus,

      dateStarted:
          data.dateStarted,

      dateCompleted:
          DateTime.now(),

      mileage:
          data.mileage ?? 0,

      overallResult:
          data.overallResult,

      inspectionScore:
          data.inspectionScore,

      criticalFailures:
          data.criticalFailures,

      advisories:
          data.advisories,

      repairsRequired:
          data.repairsRequired,

      labourHours:
          data.labourHours,

      totalCost:
          data.totalCost,

      notes:
          data.finalNotes ??
              data.notes,

      technicianSignature:
          data.technicianSignature,

      managerSignature:
          data.managerSignature,

      createdAt:
          data.createdAt,

      updatedAt:
          DateTime.now(),
    );
  }
}