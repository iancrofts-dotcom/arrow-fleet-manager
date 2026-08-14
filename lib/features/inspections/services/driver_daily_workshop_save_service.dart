import '../../vehicles/models/vehicle.dart';
import '../../../database/app_database.dart';
import '../../workshop/models/inspection_checklist_item.dart';
import '../../workshop/models/inspection_photo.dart';
import '../../workshop/models/inspection_item.dart' as workshop_item;
import '../../workshop/repositories/inspection_photo_repository.dart';
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
    AppDatabase? database,
    InspectionService? legacyInspectionService,
    WorkshopRepository? workshopRepository,
    RepairJobGenerator? repairJobGenerator,
    InspectionPhotoRepository? photoRepository,
  }) : _database = database ?? AppDatabase() {
    _legacyInspectionService =
        legacyInspectionService ?? InspectionService(database: _database);
    _workshopRepository =
        workshopRepository ?? WorkshopRepository(database: _database);
    _repairJobGenerator = repairJobGenerator ?? RepairJobGenerator();
    _photoRepository =
        photoRepository ?? InspectionPhotoRepository(database: _database);
  }

  final AppDatabase _database;
  late final InspectionService _legacyInspectionService;
  late final WorkshopRepository _workshopRepository;
  late final RepairJobGenerator _repairJobGenerator;
  late final InspectionPhotoRepository _photoRepository;

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

    final db = await _database.database();
    return db.transaction((txn) async {
      final existingLegacyInspection =
          await _legacyInspectionService.getInspectionByNumber(
        inspection.inspectionNumber,
        executor: txn,
      );
      final existingWorkshopInspection =
          await _workshopRepository.getInspectionByNumber(
        inspection.inspectionNumber,
        executor: txn,
      );

      if (existingLegacyInspection != null &&
          existingWorkshopInspection != null) {
        final existingWorkshopInspectionId = existingWorkshopInspection.id;
        if (existingWorkshopInspectionId == null) {
          throw StateError('Existing workshop inspection has no database ID.');
        }
        return existingWorkshopInspectionId;
      }

      if (existingLegacyInspection != null ||
          existingWorkshopInspection != null) {
        throw StateError(
          'An incomplete previous submission exists for this inspection number.',
        );
      }

      await _legacyInspectionService.saveInspectionWithResults(
        inspection,
        items,
        executor: txn,
      );

      final workshopInspectionId = await _workshopRepository.createInspection(
        workshopInspection,
        executor: txn,
      );
      final savedItems = _mapWorkshopItems(
        inspectionId: workshopInspectionId,
        items: workshopChecklistItems,
      );
      await _workshopRepository.addInspectionItems(
        savedItems,
        executor: txn,
      );

      final generatedJobs = _repairJobGenerator.generate(
        inspectionId: workshopInspectionId,
        vehicleId: vehicleId,
        vehicleRegistration: vehicle.registration,
        items: workshopChecklistItems,
      );
      final persistedItems = await _workshopRepository.getInspectionItems(
        workshopInspectionId,
        executor: txn,
      );
      if (persistedItems.length != workshopChecklistItems.length) {
        throw StateError('Workshop inspection items were not saved completely.');
      }

      final photos = <InspectionPhoto>[];
      for (var index = 0; index < workshopChecklistItems.length; index++) {
        final inspectionItemId = persistedItems[index].id;
        if (inspectionItemId == null) {
          throw StateError('Saved workshop inspection item has no database ID.');
        }

        for (final filePath in workshopChecklistItems[index].photos) {
          if (filePath.trim().isEmpty) continue;
          photos.add(
            InspectionPhoto(
              inspectionId: workshopInspectionId,
              inspectionItemId: inspectionItemId,
              filePath: filePath,
              createdAt: now,
            ),
          );
        }
      }
      await _photoRepository.createPhotos(photos, executor: txn);

      for (var index = 0; index < generatedJobs.length; index++) {
        final inspectionItemId = persistedItems[repairSourceIndexes[index]].id;
        if (inspectionItemId == null) {
          throw StateError('Saved workshop inspection item has no database ID.');
        }
        await _workshopRepository.createRepairJob(
          generatedJobs[index].copyWith(inspectionItemId: inspectionItemId),
          executor: txn,
        );
      }

      return workshopInspectionId;
    });
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
            photos: _photoPaths(item.photoPath),
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
            photoCount: entry.value.photos.length,
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
      case ChecklistStatus.notApplicable:
        return workshop_item.InspectionItemStatus.notApplicable;
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

  List<String> _photoPaths(String? photoPath) {
    if (photoPath == null || photoPath.trim().isEmpty) {
      return const [];
    }

    return [photoPath];
  }

  String _notes(Inspection inspection) {
    final notes = <String>['Fuel level: ${inspection.fuelLevel}'];
    if (inspection.comments.trim().isNotEmpty) {
      notes.add(inspection.comments.trim());
    }
    return notes.join('\n\n');
  }
}
