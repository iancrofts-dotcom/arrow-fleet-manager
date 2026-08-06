import '../models/inspection_item.dart';
import '../models/workshop_inspection.dart';
import '../repositories/inspection_template_repository.dart';
import '../repositories/workshop_repository.dart';

/// ============================================================================
/// INSPECTION GENERATOR
/// ============================================================================
///
/// Generates a new workshop inspection from a stored inspection template.
/// Every generated inspection item starts with a status of N/A.
/// ============================================================================

class InspectionGenerator {
  final WorkshopRepository _workshopRepository;
  final InspectionTemplateRepository _templateRepository;

  InspectionGenerator(
    this._workshopRepository,
    this._templateRepository,
  );


  /// --------------------------------------------------------------------------
  /// Create a new inspection from a template
  /// --------------------------------------------------------------------------
  Future<int> generateInspection({
    required WorkshopInspection inspection,
    required int templateId,
  }) async {
    // Create inspection header
    final inspectionId =
        await _workshopRepository.createInspection(inspection);

    // Load template items
    final templateItems =
        await _templateRepository.getTemplateItems(templateId);

    // Convert template items into inspection items
    final inspectionItems = templateItems.map((templateItem) {
      return InspectionItem(
        inspectionId: inspectionId,
        category: templateItem.category,
        title: templateItem.title,
        status: templateItem.defaultStatus,
        mandatory: templateItem.mandatory,
        repairRequired: false,
        notes: '',
        photoCount: 0,
        displayOrder: templateItem.displayOrder,
      );
    }).toList();

    // Save all inspection items in a single batch
    await _workshopRepository.addInspectionItems(
      inspectionItems,
    );

    return inspectionId;
  }
}