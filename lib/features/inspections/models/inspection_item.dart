enum InspectionStatus {
  pass,
  fail,
  notApplicable,
}

class InspectionItem {
  final String title;
  final String category;

  InspectionStatus status;
  String notes;

  InspectionItem({
    required this.title,
    required this.category,
    this.status = InspectionStatus.pass,
    this.notes = '',
  });
}