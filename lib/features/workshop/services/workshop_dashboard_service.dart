import '../models/workshop_dashboard_data.dart';
import '../repositories/workshop_repository.dart';

class WorkshopDashboardService {
  final WorkshopRepository _repository;

  WorkshopDashboardService(this._repository);

  Future<WorkshopDashboardData> loadDashboard() async {
    final openInspections = await _repository.getOpenInspectionCount();
    final completedToday = await _repository.getCompletedInspectionCount();
    final criticalFailures = await _repository.getCriticalFailureCount();
    final repairsRequired = await _repository.getRepairRequiredCount();

    return WorkshopDashboardData(
      openInspections: openInspections,
      completedToday: completedToday,
      criticalFailures: criticalFailures,
      repairsRequired: repairsRequired,
    );
  }
}