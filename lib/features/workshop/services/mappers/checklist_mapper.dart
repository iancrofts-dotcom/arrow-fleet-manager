import '../../models/inspection_checklist_item.dart';
import '../../models/inspection_item.dart';

class ChecklistMapper {
  const ChecklistMapper();

  List<InspectionItem> mapList(
    int inspectionId,
    List<InspectionChecklistItem> items,
  ) {
    return items
        .asMap()
        .entries
        .map(
          (entry) => map(
            inspectionId,
            entry.key,
            entry.value,
          ),
        )
        .toList();
  }

  InspectionItem map(
    int inspectionId,
    int displayOrder,
    InspectionChecklistItem item,
  ) {
    return InspectionItem(
      inspectionId: inspectionId,

      category: _category(item.category),

      sectionTitle: item.category,

      title: item.title,

      responseType: item.responseType,

      responseValue: item.responseValue.trim().isEmpty
          ? null
          : item.responseValue.trim(),

      status: _status(item.status),

      mandatory: item.mandatory,

      repairRequired: item.repairRequired,

      notes: item.notes,

      photoCount: item.photos.length,

      displayOrder: displayOrder,
    );
  }

  InspectionItemStatus _status(
    ChecklistStatus status,
  ) {
    switch (status) {
      case ChecklistStatus.pending:
        return InspectionItemStatus.notApplicable;

      case ChecklistStatus.pass:
        return InspectionItemStatus.pass;

      case ChecklistStatus.advisory:
        return InspectionItemStatus.advisory;

      case ChecklistStatus.fail:
        return InspectionItemStatus.fail;

      case ChecklistStatus.notApplicable:
        return InspectionItemStatus.notApplicable;
    }
  }

  InspectionCategory _category(
    String category,
  ) {
    switch (category.toLowerCase()) {
      case 'vehicle information':
        return InspectionCategory.vehicleInformation;

      case 'exterior':
        return InspectionCategory.exterior;

      case 'bodywork':
        return InspectionCategory.bodywork;

      case 'wheels':
      case 'tyres':
      case 'wheels & tyres':
        return InspectionCategory.wheelsTyres;

      case 'brakes':
        return InspectionCategory.brakes;

      case 'steering':
        return InspectionCategory.steering;

      case 'suspension':
        return InspectionCategory.suspension;

      case 'engine':
        return InspectionCategory.engine;

      case 'transmission':
        return InspectionCategory.transmission;

      case 'electrical':
        return InspectionCategory.electrical;

      case 'interior':
        return InspectionCategory.interior;

      case 'underbody':
        return InspectionCategory.underbody;

      case 'road test':
        return InspectionCategory.roadTest;

      case 'sign off':
      case 'sign-off':
        return InspectionCategory.signOff;

      default:
        return InspectionCategory.vehicleInformation;
    }
  }
}
