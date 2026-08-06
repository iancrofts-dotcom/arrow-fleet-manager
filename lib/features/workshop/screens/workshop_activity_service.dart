import '../models/workshop_activity.dart';
import '../repositories/workshop_repository.dart';

class WorkshopActivityService {
  final WorkshopRepository _repository;

  WorkshopActivityService(this._repository);

  Future<List<WorkshopActivity>> getRecentActivity() async {
    final inspections = await _repository.getAllInspections();

    inspections.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return inspections.take(10).map((inspection) {
      return WorkshopActivity.fromInspection(
        registration: inspection.registration,
        inspectionNumber: inspection.inspectionNumber,
        status: inspection.status.name,
        dateTime: inspection.createdAt,
      );
    }).toList();
  }
}