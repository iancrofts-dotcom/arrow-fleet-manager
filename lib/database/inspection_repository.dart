import '../features/inspections/models/inspection.dart';
import 'database_service.dart';

class InspectionRepository {
  final DatabaseService databaseService;

  InspectionRepository({
    required this.databaseService,
  });

  Future<void> saveInspection(
    Inspection inspection,
  ) async {
    final db = await databaseService.database.database();

    await db.insert(
      'inspections',
      {
        'inspectionNumber': inspection.inspectionNumber,
        'inspectionDate':
            inspection.inspectionDate.toIso8601String(),
        'registration': inspection.registration,
        'driver': inspection.driver,
        'inspector': inspection.inspector,
        'mileage': inspection.mileage,
        'comments': inspection.comments,
      },
    );
  }
}