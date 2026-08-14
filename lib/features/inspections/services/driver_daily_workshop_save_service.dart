import '../../vehicles/models/vehicle.dart';
import '../../workshop/models/inspection_checklist_item.dart';
import '../../workshop/models/inspection_item.dart' as workshop_item;
import '../../workshop/models/workshop_inspection.dart';
import '../../workshop/repositories/workshop_repository.dart';
import '../../workshop/services/repair_job_generator.dart';
import '../models/inspection.dart';
import '../models/inspection_item.dart' as daily_item;
import 'inspection_service.dart';

/// Persists a Driver Daily Inspection in the existing legacy history and in
/// the Workshop inspection workflow until legacy history consumers migrate.
class DriverDailyWorkshopSaveService {
  DriverDailyWorkshopSaveService({
    InspectionService? legacyInspectionService,
    WorkshopRepository? workshopRepository,
    RepairJobGenerator? repairJobGenerator,
  })  : _legacyInspectionService =
            legacyInspectionService ?? InspectionService(),
        _workshopRepository = workshopRepository ?? WorkshopRepository(),
        _repairJobGenerator = repairJobGenerator ?? RepairJobGenerator();

  final InspectionService _legacyInspectionService;
  final WorkshopRepository _workshopRepository;
  final RepairJobGenerator _repairJobGenerator;

  Future<int> save({
    required Inspection inspection,
    required List<daily_item.InspectionItem> items,
    required int driverId,
    required String driverName,
    required Vehicle vehicle,
  }) async {
    final vehicleId = vehicle.id;
    if (vehicleId == null) {
      throw ArgumentError('Assigned vehicle must have a database ID.');
    }

    final existingWorkshopInspection =
        await _workshopRepository.getInspectionByNumber(
      inspection.inspectionNumber,
    );
    final existingWorkshopInspectionId = existingWorkshopInspection?.id;
    if (existingWorkshopInspectionId != null) {
      return existingWorkshopInspectionId;
    }

    final existingLegacyInspection =
        await _legacyInspectionService.getInspectionByNumber(
      inspection.inspectionNumber,
    );
    if (existingLegacyInspection == null) {
      await _legacyInspectionService.saveInspectionWithResults(
        inspection,
        items,
      );
    }

    final workshopChecklistItems = _mapChecklistItems(items);
    final repairSourceIndexes = <int>[];
    for (var index = 0; index < workshopChecklistItems.length; index++) {
      final item = workshopChecklistItems[index];
      if (item.failed || item.repairRequired) {
        repairSourceIndexes.add(index);
      }
    }

    final repairsRequired = repairSourceIndexes.length;
    final now = DateTime.now();
    final workshopInspection = WorkshopInspection(
      inspectionNumber: inspection.inspectionNumber,
      vehicleId: vehicleId,
      registration: vehicle.registration,
      fleetNumber: vehicle.fleetNumber,
      technicianName: '',
      driverId: driverId,
      driverName: driverName,
      inspectionType: WorkshopInspectionType.driverDailyInspection,
      status: repairsRequired > 0
          ? WorkshopInspectionStatus.awaitingRepair
          : WorkshopInspectionStatus.completed,
      vehicleStatus: repairsRequired > 0
          ? VehicleWorkshopStatus.awaitingRepair
          : VehicleWorkshopStatus.roadworthy,
      dateStarted: inspection.inspectionDate,
      dateCompleted: now,
      mileage: inspection.mileage,
      overallResult: repairsRequired > 0
          ? InspectionResult.fail
          : InspectionResult.pass,
      inspectionScore: _inspectionScore(items),
      criticalFailures: 0,
      advisories: 0,
      repairsRequired: repairsRequired,
      labourHours: 0,
      totalCost: 0,
      notes: _notes(inspection),
      createdAt: now,
      updatedAt: now,
    );

    final workshopInspectionId =
        await _workshopRepository.createInspection(workshopInspection);
    final savedItems = _mapWorkshopItems(
      inspectionId: workshopInspectionId,
      items: workshopChecklistItems,
    );
    await _workshopRepository.addInspectionItems(savedItems);

    final generatedJobs = _repairJobGenerator.generate(
      inspectionId: workshopInspectionId,
      vehicleId: vehicleId,
      vehicleRegistration: vehicle.registration,
      items: workshopChecklistItems,
    );
    final persistedItems = await _workshopRepository.getInspectionItems(
      workshopInspectionId,
    );

    for (var index = 0; index < generatedJobs.length; index++) {
      final sourceIndex = repairSourceIndexes[index];
      final inspectionItemId = persistedItems[sourceIndex].id;
      if (inspectionItemId == null) {
        throw StateError('Saved workshop inspection item has no database ID.');
      }
      await _workshopRepository.createRepairJob(
        generatedJobs[index].copyWith(
          inspectionItemId: inspectionItemId,
        ),
      );
    }

    return workshopInspectionId;
  }

  List<InspectionChecklistItem> _mapChecklistItems(
    List<daily_item.InspectionItem> items,
  ) {
    return items
        .map(
          (item) => InspectionChecklistItem(
            id: item.id,
            category: item.category,
            title: item.title,
            status: _checklistStatus(item.status),
            repairRequired: item.hasFailed,
            notes: item.notes,
          ),
        )
        .toList(growable: false);
  }

  List<workshop_item.InspectionItem> _mapWorkshopItems({
    required int inspectionId,
    required List<InspectionChecklistItem> items,
  }) {
    return items
        .asMap()
        .entries
        .map(
          (entry) => workshop_item.InspectionItem(
            inspectionId: inspectionId,
            category: _category(entry.value.category),
            title: entry.value.title,
            status: _itemStatus(entry.value.status),
            repairRequired: entry.value.repairRequired,
            notes: entry.value.notes,
            displayOrder: entry.key,
          ),
        )
        .toList(growable: false);
  }

  ChecklistStatus _checklistStatus(daily_item.InspectionStatus status) {
    switch (status) {
      case daily_item.InspectionStatus.pass:
        return ChecklistStatus.pass;
      case daily_item.InspectionStatus.fail:
        return ChecklistStatus.fail;
      case daily_item.InspectionStatus.notApplicable:
        return ChecklistStatus.pending;
    }
  }

  workshop_item.InspectionItemStatus _itemStatus(ChecklistStatus status) {
    switch (status) {
      case ChecklistStatus.pass:
        return workshop_item.InspectionItemStatus.pass;
      case ChecklistStatus.fail:
        return workshop_item.InspectionItemStatus.fail;
      case ChecklistStatus.pending:
        return workshop_item.InspectionItemStatus.notApplicable;
      case ChecklistStatus.advisory:
        return workshop_item.InspectionItemStatus.advisory;
    }
  }

  workshop_item.InspectionCategory _category(String category) {
    switch (category.toLowerCase()) {
      case 'exterior':
        return workshop_item.InspectionCategory.exterior;
      case 'accessibility':
        return workshop_item.InspectionCategory.interior;
      case 'safety':
        return workshop_item.InspectionCategory.vehicleInformation;
      default:
        return workshop_item.InspectionCategory.vehicleInformation;
    }
  }

  int _inspectionScore(List<daily_item.InspectionItem> items) {
    if (items.isEmpty) {
      return 0;
    }

    final passed = items.where((item) => item.hasPassed).length;
    return ((passed / items.length) * 100).round();
  }

  String _notes(Inspection inspection) {
    final notes = <String>['Fuel level: ${inspection.fuelLevel}'];
    if (inspection.comments.trim().isNotEmpty) {
      notes.add(inspection.comments.trim());
    }
    return notes.join('\n\n');
  }
}
