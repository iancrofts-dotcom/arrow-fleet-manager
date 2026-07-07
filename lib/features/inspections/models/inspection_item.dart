enum InspectionStatus {
  pass,
  fail,
  na,
}

class InspectionItem {

  final String title;

  InspectionStatus status;

  String notes;

  InspectionItem({
    required this.title,
    this.status = InspectionStatus.pass,
    this.notes = "",
  });

}