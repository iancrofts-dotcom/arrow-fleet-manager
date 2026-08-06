class WorkshopActivity {
  final String title;
  final String description;
  final String type;
  final DateTime dateTime;

  const WorkshopActivity({
    required this.title,
    required this.description,
    required this.type,
    required this.dateTime,
  });

  factory WorkshopActivity.fromInspection({
    required String registration,
    required String inspectionNumber,
    required String status,
    required DateTime dateTime,
  }) {
    return WorkshopActivity(
      title: 'Inspection $status',
      description: '$registration • $inspectionNumber',
      type: 'inspection',
      dateTime: dateTime,
    );
  }

  factory WorkshopActivity.fromRepair({
    required String registration,
    required String repairNumber,
    required String status,
    required DateTime dateTime,
  }) {
    return WorkshopActivity(
      title: 'Repair $status',
      description: '$registration • $repairNumber',
      type: 'repair',
      dateTime: dateTime,
    );
  }
}