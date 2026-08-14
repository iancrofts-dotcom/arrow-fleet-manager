import '../models/repair_job.dart';
import '../models/workshop_activity.dart';
import '../models/workshop_dashboard_data.dart';
import '../models/workshop_inspection.dart';
import '../repositories/workshop_repository.dart';
import '../screens/workshop_activity_service.dart';

class WorkshopDashboardService {
  final WorkshopRepository _repository;

  WorkshopDashboardService(this._repository);

  Future<WorkshopDashboardData> loadDashboard() async {
    final dashboardSources = await Future.wait([
      _repository.getAllInspections(),
      _repository.getAllRepairJobs(),
      WorkshopActivityService(_repository).getRecentActivity(),
    ]);
    final inspections = dashboardSources[0] as List<WorkshopInspection>;
    final repairJobs = dashboardSources[1] as List<RepairJob>;
    final recentActivity = dashboardSources[2] as List<WorkshopActivity>;

    // Open means the inspection still requires workshop operational work.
    // Completed inspections awaiting manager sign-off are tracked separately.
    final openInspections = inspections.where((inspection) {
      if (inspection.status == WorkshopInspectionStatus.signedOff) {
        return false;
      }

      if (inspection.status == WorkshopInspectionStatus.cancelled) {
        return false;
      }

      return inspection.status != WorkshopInspectionStatus.completed;
    }).length;

    // Completed Today is independent of the current status.
    // Once an inspection has a completion timestamp, it remains part of
    // today's productivity figure even if it has subsequently been signed off.
    final now = DateTime.now();
    final dayStart = DateTime(
      now.year,
      now.month,
      now.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final completedToday = inspections.where((inspection) {
      final completedAt = inspection.dateCompleted;
      if (completedAt == null) {
        return false;
      }

      return !completedAt.isBefore(dayStart) &&
          completedAt.isBefore(dayEnd);
    }).length;

    final repairsOutstanding = repairJobs.where((job) {
      return job.status != RepairJobStatus.completed &&
          job.status != RepairJobStatus.cancelled;
    }).length;

    final awaitingParts = repairJobs.where((job) {
      return job.status == RepairJobStatus.awaitingParts;
    }).length;

    final awaitingSignOff = inspections.where((inspection) {
      final signature = inspection.managerSignature;
      return inspection.status == WorkshopInspectionStatus.completed &&
          (signature == null || signature.trim().isEmpty);
    }).length;

    final criticalFailures =
        await _repository.getCriticalFailureCount();
    final repairsRequired =
        await _repository.getRepairRequiredCount();

    return WorkshopDashboardData(
      openInspections: openInspections,
      completedToday: completedToday,
      criticalFailures: criticalFailures,
      repairsRequired: repairsRequired,
      repairsOutstanding: repairsOutstanding,
      awaitingParts: awaitingParts,
      awaitingSignOff: awaitingSignOff,
      recentActivity: recentActivity,
    );
  }
}
