import '../../vehicles/models/vehicle.dart';
import 'inspection.dart';
import 'inspection_item.dart';

class InspectionSession {
  final Inspection inspection;

  Vehicle? vehicle;

  final List<InspectionItem> items;

  InspectionSession({
    required this.inspection,
    required this.items,
    this.vehicle,
  });

  int get completedChecks =>
      items
          .where(
            (item) => item.status != InspectionStatus.notApplicable,
          )
          .length;

  int get failedChecks =>
      items
          .where(
            (item) => item.status == InspectionStatus.fail,
          )
          .length;

  bool get hasFailures => failedChecks > 0;

  List<InspectionItem> get failedItems =>
      items
          .where(
            (item) => item.status == InspectionStatus.fail,
          )
          .toList();

  List<InspectionItem> itemsByCategory(String category) {
    return items
        .where(
          (item) => item.category == category,
        )
        .toList();
  }

  void updateStatus(
    InspectionItem item,
    InspectionStatus status,
  ) {
    item.status = status;
  }

  void updateNotes(
    InspectionItem item,
    String notes,
  ) {
    item.notes = notes;
  }

  void reset() {
    vehicle = null;

    for (final item in items) {
      item.status = InspectionStatus.pass;
      item.notes = '';
    }
  }
}