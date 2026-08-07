import '../models/inspection_wizard_data.dart';
import '../repositories/workshop_repository.dart';
import 'mappers/checklist_mapper.dart';
import 'mappers/inspection_mapper.dart';

class InspectionSaveService {
  InspectionSaveService({
    WorkshopRepository? repository,
    InspectionMapper? inspectionMapper,
    ChecklistMapper? checklistMapper,
  })  : _repository = repository ?? WorkshopRepository(),
        _inspectionMapper =
            inspectionMapper ?? const InspectionMapper(),
        _checklistMapper =
            checklistMapper ?? const ChecklistMapper();

  final WorkshopRepository _repository;
  final InspectionMapper _inspectionMapper;
  final ChecklistMapper _checklistMapper;

  Future<int> saveInspection(
    InspectionWizardData data,
  ) async {
    // Convert wizard data into the database model.
    final inspection =
        _inspectionMapper.map(data);

    // Save inspection.
    final inspectionId =
        await _repository.createInspection(
      inspection,
    );

    // Convert checklist.
    final inspectionItems =
        _checklistMapper.mapList(
      inspectionId,
      data.checklistItems,
    );

    // Save checklist.
    await _repository.addInspectionItems(
      inspectionItems,
    );

    // Save repair jobs.
    for (final repair in data.repairJobs) {
      await _repository.createRepairJob(
        repair.copyWith(
          inspectionId: inspectionId,
        ),
      );
    }

    return inspectionId;
  }
}