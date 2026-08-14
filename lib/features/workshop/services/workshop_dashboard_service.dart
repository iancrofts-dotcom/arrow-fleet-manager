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

    final unresolvedRepairJobs = repairJobs.where((job) {
      switch (job.status) {
        case RepairJobStatus.open:
        case RepairJobStatus.assigned:
        case RepairJobStatus.inProgress:
        case RepairJobStatus.awaitingParts:
        case RepairJobStatus.awaitingInspection:
          return true;
        case RepairJobStatus.completed:
        case RepairJobStatus.cancelled:
          return false;
      }
    }).toList(growable: false);

    // One inspection with several jobs is one current repair requirement.
    final repairsRequired = unresolvedRepairJobs
        .map((job) => job.inspectionId)
        .toSet()
        .length;
    final repairsOutstanding = unresolvedRepairJobs.length;

    final awaitingParts = repairJobs.where((job) {
      return job.status == RepairJobStatus.awaitingParts;
    }).length;

    final awaitingSignOff = inspections.where((inspection) {
      final signature = inspection.managerSignature;
      return inspection.status == WorkshopInspectionStatus.completed &&
          (signature == null || signature.trim().isEmpty);
    }).length;

    // Repair jobs do not retain an item-level criticality flag. The reliable
    // current operational definition is critical failures on inspections that
    // are still being worked: draft, in progress, or awaiting repair.
    final criticalFailures = inspections.where((inspection) {
      return inspection.status == WorkshopInspectionStatus.draft ||
          inspection.status == WorkshopInspectionStatus.inProgress ||
          inspection.status == WorkshopInspectionStatus.awaitingRepair;
    }).fold<int>(
      0,
      (total, inspection) => total + inspection.criticalFailures,
    );

    return WorkshopDashboardData(
      openInspections: openInspections,
      completedToday: completedToday,
      criticalFailures: criticalFailures,
      repairsRequired: repairsRequired,
      inspectionTotal: inspections.length,
      defectTotal: repairJobs.length,
      repairsOutstanding: repairsOutstanding,
      awaitingParts: awaitingParts,
      awaitingSignOff: awaitingSignOff,
      recentActivity: recentActivity,
    );
  }
}
