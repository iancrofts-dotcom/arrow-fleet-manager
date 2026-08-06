import '../models/inspection_item.dart';

/// ============================================================================
/// WORKSHOP TEMPLATE SERVICE
/// ============================================================================
///
/// Generates the default inspection checklist for new workshop inspections.
///
/// This service is intentionally database-independent.
/// It simply creates InspectionItem objects that can later be saved using
/// WorkshopRepository.addInspectionItems().
/// ============================================================================

class WorkshopTemplateService {
  const WorkshopTemplateService();

  List<InspectionItem> createDefaultPmiChecklist({
    required int inspectionId,
  }) {
    final items = <_TemplateItem>[
      _TemplateItem(
        InspectionCategory.vehicleInformation,
        'Vehicle Information',
      ),
      _TemplateItem(
        InspectionCategory.exterior,
        'Exterior',
      ),
      _TemplateItem(
        InspectionCategory.bodywork,
        'Bodywork',
      ),
      _TemplateItem(
        InspectionCategory.wheelsTyres,
        'Wheels & Tyres',
      ),
      _TemplateItem(
        InspectionCategory.brakes,
        'Brakes',
      ),
      _TemplateItem(
        InspectionCategory.steering,
        'Steering',
      ),
      _TemplateItem(
        InspectionCategory.suspension,
        'Suspension',
      ),
      _TemplateItem(
        InspectionCategory.engine,
        'Engine',
      ),
      _TemplateItem(
        InspectionCategory.transmission,
        'Transmission',
      ),
      _TemplateItem(
        InspectionCategory.electrical,
        'Electrical',
      ),
      _TemplateItem(
        InspectionCategory.interior,
        'Interior',
      ),
      _TemplateItem(
        InspectionCategory.underbody,
        'Underbody',
      ),
      _TemplateItem(
        InspectionCategory.roadTest,
        'Road Test',
      ),
      _TemplateItem(
        InspectionCategory.signOff,
        'Sign Off',
      ),
    ];

    return List.generate(
      items.length,
      (index) {
        final item = items[index];

        return InspectionItem(
          inspectionId: inspectionId,
          category: item.category,
          title: item.title,
          status: InspectionItemStatus.notApplicable,
          mandatory: true,
          repairRequired: false,
          notes: '',
          photoCount: 0,
          displayOrder: index + 1,
        );
      },
    );
  }
}

class _TemplateItem {
  final InspectionCategory category;
  final String title;

  const _TemplateItem(
    this.category,
    this.title,
  );
}