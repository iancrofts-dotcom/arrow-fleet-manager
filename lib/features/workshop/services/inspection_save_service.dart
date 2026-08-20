import '../models/inspection_wizard_data.dart';
import '../models/inspection_photo.dart';
import '../repositories/inspection_photo_repository.dart';
import '../repositories/workshop_repository.dart';
import 'mappers/checklist_mapper.dart';
import 'mappers/inspection_mapper.dart';
import 'repair_job_generator.dart';

class InspectionSaveService {
  InspectionSaveService({
    WorkshopRepository? repository,
    InspectionMapper? inspectionMapper,
    ChecklistMapper? checklistMapper,
    InspectionPhotoRepository? photoRepository,
    RepairJobGenerator? repairJobGenerator,
  }) : _repository = repository ?? WorkshopRepository(),
       _inspectionMapper = inspectionMapper ?? const InspectionMapper(),
       _checklistMapper = checklistMapper ?? const ChecklistMapper(),
       _photoRepository = photoRepository ?? InspectionPhotoRepository(),
       _repairJobGenerator = repairJobGenerator ?? RepairJobGenerator();

  final WorkshopRepository _repository;
  final InspectionMapper _inspectionMapper;
  final ChecklistMapper _checklistMapper;
  final InspectionPhotoRepository _photoRepository;
  final RepairJobGenerator _repairJobGenerator;

  Future<int> saveInspection(InspectionWizardData data) async {
    return _repository.transaction((executor) async {
      // The initial value exists only inside this transaction. The final,
      // stable number is derived from SQLite's generated inspection ID below.
      final pendingInspection = _inspectionMapper
          .map(data)
          .copyWith(inspectionNumber: 'PENDING');
      final inspectionId = await _repository.createInspection(
        pendingInspection,
        executor: executor,
      );
      final inspectionNumber = _inspectionNumber(data, inspectionId);
      await _repository.updateInspection(
        pendingInspection.copyWith(
          id: inspectionId,
          inspectionNumber: inspectionNumber,
          updatedAt: DateTime.now(),
        ),
        executor: executor,
      );

      final inspectionItems = _checklistMapper.mapList(
        inspectionId,
        data.checklistItems,
      );
      await _repository.addInspectionItems(inspectionItems, executor: executor);

      // Reload the persisted rows in display order so photos and repairs are
      // linked to their database-generated item IDs, not wizard placeholders.
      final savedItems = await _repository.getInspectionItems(
        inspectionId,
        executor: executor,
      );
      if (savedItems.length != data.checklistItems.length) {
        throw StateError(
          'Workshop inspection items were not saved completely.',
        );
      }

      final photos = <InspectionPhoto>[];
      for (var index = 0; index < data.checklistItems.length; index++) {
        final itemId = savedItems[index].id;
        if (itemId == null) {
          throw StateError(
            'Saved workshop inspection item has no database ID.',
          );
        }
        for (final filePath in data.checklistItems[index].photos) {
          if (filePath.trim().isEmpty) continue;
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
      await _photoRepository.createPhotos(photos, executor: executor);

      for (var sequence = 0; sequence < data.repairJobs.length; sequence++) {
        final repair = data.repairJobs[sequence];
        final sourceIndex = repair.inspectionItemId - 1;
        if (sourceIndex < 0 || sourceIndex >= savedItems.length) {
          throw StateError('Repair job source item could not be resolved.');
        }
        final sourceItemId = savedItems[sourceIndex].id;
        if (sourceItemId == null) {
          throw StateError('Saved repair source item has no database ID.');
        }
        await _repository.createRepairJob(
          repair.copyWith(
            jobNumber: _repairJobGenerator.jobNumberFor(
              inspectionId: inspectionId,
              sequence: sequence + 1,
              createdAt: repair.createdAt,
            ),
            inspectionId: inspectionId,
            inspectionItemId: sourceItemId,
          ),
          executor: executor,
        );
      }

      return inspectionId;
    });
  }

  String _inspectionNumber(InspectionWizardData data, int inspectionId) {
    final year = data.dateStarted.year;
    return 'WI-$year-${inspectionId.toString().padLeft(6, '0')}';
  }
}
