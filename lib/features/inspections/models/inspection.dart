class Inspection {
  final String inspectionNumber;
  final DateTime inspectionDate;

  String registration;
  String driver;
  String inspector;
  int mileage;

  String comments;

  Inspection({
    required this.inspectionNumber,
    required this.inspectionDate,
    this.registration = '',
    this.driver = '',
    this.inspector = '',
    this.mileage = 0,
    this.comments = '',
  });
}