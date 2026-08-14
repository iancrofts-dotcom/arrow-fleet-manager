import '../models/inspection_wizard_data.dart';
import '../models/inspection_photo.dart';
import '../repositories/inspection_photo_repository.dart';
import '../repositories/workshop_repository.dart';
import 'mappers/checklist_mapper.dart';
import 'mappers/inspection_mapper.dart';

class InspectionSaveService {
  InspectionSaveService({
    WorkshopRepository? repository,
    InspectionMapper? inspectionMapper,
    ChecklistMapper? checklistMapper,
    InspectionPhotoRepository? photoRepository,
  })  : _repository =
            repository ?? WorkshopRepository(),
        _inspectionMapper =
            inspectionMapper ?? const InspectionMapper(),
        _checklistMapper =
            checklistMapper ?? const ChecklistMapper(),
        _photoRepository =
            photoRepository ?? InspectionPhotoRepository();

  final WorkshopRepository _repository;
  final InspectionMapper _inspectionMapper;
  final ChecklistMapper _checklistMapper;
  final InspectionPhotoRepository _photoRepository;

  Future<int> saveInspection(
    InspectionWizardData data,
  ) async {
    // Convert wizard data into the database model.
    final inspection =
        _inspectionMapper.map(data);

    // Save inspection header first so we have its database ID.
    final inspectionId =
        await _repository.createInspection(
      inspection,
    );

    // Convert and save checklist items.
    final inspectionItems =
        _checklistMapper.mapList(
      inspectionId,
      data.checklistItems,
    );

    await _repository.addInspectionItems(
      inspectionItems,
    );

    // Reload the persisted checklist rows so we have the
    // database-generated item IDs needed by the photo table.
    final savedItems =
        await _repository.getInspectionItems(
      inspectionId,
    );

    // Save every photo against its corresponding persisted
    // checklist item.
    final photos = <InspectionPhoto>[];

    for (var index = 0;
        index < data.checklistItems.length &&
            index < savedItems.length;
        index++) {
      final wizardItem = data.checklistItems[index];
      final savedItem = savedItems[index];

      final itemId = savedItem.id;
      if (itemId == null) {
        continue;
      }

      for (final filePath in wizardItem.photos) {
        if (filePath.trim().isEmpty) {
          continue;
        }

        photos.add(
          InspectionPhoto(
            inspectionId: inspectionId,
            inspectionItemId: itemId,
            filePath: filePath,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    await _photoRepository.createPhotos(photos);

    // Save repair jobs.
    for (final repair in data.repairJobs) {
      await _repository.createRepairJob(
        repair.copyWith(
          inspectionId: inspectionId,
          technicianId: data.technicianId,
          technicianName: data.technicianName ?? '',
        ),
      );
    }

    return inspectionId;
  }
}
