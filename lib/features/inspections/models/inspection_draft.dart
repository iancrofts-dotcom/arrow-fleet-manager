import '../../vehicles/models/vehicle.dart';
import 'inspection_item.dart';

class InspectionDraft {
  Vehicle? vehicle;

  String driver;
  int mileage;
  String comments;

  List<InspectionItem> checklistItems;

  InspectionDraft({
    this.vehicle,
    this.driver = '',
    this.mileage = 0,
    this.comments = '',
    List<InspectionItem>? checklistItems,
  }) : checklistItems = checklistItems ?? [];

  bool get hasVehicle => vehicle != null;

  bool get hasChecklist =>
      checklistItems.isNotEmpty;

  bool get hasFailures =>
      checklistItems.any((item) => item.hasFailed);

  bool get isValid {
    return vehicle != null &&
        driver.trim().isNotEmpty &&
        mileage > 0;
  }  

  List<InspectionItem> get failedItems =>
      checklistItems
          .where((item) => item.hasFailed)
          .toList();

  List<InspectionItem> get passedItems =>
      checklistItems
          .where((item) => item.hasPassed)
          .toList();

  void clear() {
    vehicle = null;
    driver = '';
    mileage = 0;
    comments = '';
    checklistItems.clear();
  }
}