import 'inspection_item.dart';

enum ChecklistStatus {
  pending,
  pass,
  advisory,
  fail,
  notApplicable,
}

enum ChecklistPriority {
  low,
  medium,
  high,
  critical,
}

class InspectionChecklistItem {
  final String id;
  final String category;
  final String title;
  final String? description;

  final InspectionResponseType responseType;

  ChecklistStatus status;

  ChecklistPriority priority;

  bool repairRequired;

  bool mandatory;

  bool photoRequired;

  bool autoCreateRepair;

  bool allowNotes;

  String responseValue;

  String notes;

  List<String> photos;

  InspectionChecklistItem({
  required this.id,
  required this.category,
  required this.title,
    this.description,
    this.status = ChecklistStatus.pending,
    this.priority = ChecklistPriority.medium,
    this.repairRequired = false,
    this.mandatory = true,
    this.photoRequired = false,
    this.autoCreateRepair = true,
    this.allowNotes = true,
    this.responseType = InspectionResponseType.passFailNotApplicable,
    this.responseValue = '',
    this.notes = '',
    List<String>? photos,
  }) : photos = photos ?? [];

  bool get passed => status == ChecklistStatus.pass;

  bool get failed => status == ChecklistStatus.fail;

  bool get advisoryOnly =>
      status == ChecklistStatus.advisory;

  bool get completed =>
      status != ChecklistStatus.pending;

  void reset() {
    status = ChecklistStatus.pending;
    repairRequired = false;
    notes = '';
    responseValue = '';
    photos.clear();
  }

  @override
  String toString() {
    return '$category - $title ($status)';
  }
}
