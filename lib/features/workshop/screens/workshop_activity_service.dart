import '../models/workshop_activity.dart';
import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';
import '../repositories/workshop_repository.dart';

class WorkshopActivityService {
  final WorkshopRepository _repository;

  WorkshopActivityService(this._repository);

  Future<List<WorkshopActivity>> getRecentActivity({DateTime? now}) async {
    final results = await Future.wait([
      _repository.getAllInspections(),
      _repository.getAllRepairJobs(),
    ]);
    final inspections = results[0] as List<WorkshopInspection>;
    final repairJobs = results[1] as List<RepairJob>;
    final activities = <WorkshopActivity>[
      ...inspections.expand(_activitiesForInspection),
      ...repairJobs.expand(_activitiesForRepairJob),
    ];

    final cutoff = (now ?? DateTime.now()).subtract(
      const Duration(hours: 48),
    );
    activities.removeWhere((activity) => activity.dateTime.isBefore(cutoff));
    activities.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return activities.take(10).toList();
  }

  Iterable<WorkshopActivity> _activitiesForInspection(
    WorkshopInspection inspection,
  ) sync* {
    final details = _inspectionDetails(inspection);
    final isDriverDaily = inspection.inspectionType ==
        WorkshopInspectionType.driverDailyInspection;

    yield WorkshopActivity(
      title: isDriverDaily
          ? 'Driver Daily Inspection submitted'
          : 'Workshop Inspection created',
      description: details,
      type: isDriverDaily ? 'driverDailySubmitted' : 'inspectionCreated',
      dateTime: inspection.createdAt,
    );

    if (inspection.dateCompleted != null &&
        (inspection.status == WorkshopInspectionStatus.completed ||
            inspection.status == WorkshopInspectionStatus.signedOff)) {
      yield WorkshopActivity(
        title: 'Inspection completed',
        description: details,
        type: 'inspectionCompleted',
        dateTime: inspection.dateCompleted!,
      );
    }

    if (inspection.status == WorkshopInspectionStatus.signedOff &&
        (inspection.managerSignature?.trim().isNotEmpty ?? false)) {
      yield WorkshopActivity(
        title: 'Inspection signed off',
        description: '$details • ${inspection.managerSignature}',
        type: 'inspectionSignedOff',
        dateTime: inspection.updatedAt,
      );
    }
  }

  Iterable<WorkshopActivity> _activitiesForRepairJob(RepairJob job) sync* {
    final details = '${job.jobNumber} • ${job.vehicleRegistration}';

    yield WorkshopActivity(
      title: 'Repair Job generated',
      description: details,
      type: 'repairGenerated',
      dateTime: job.createdAt,
    );

    if (job.status == RepairJobStatus.completed && job.completedAt != null) {
      yield WorkshopActivity(
        title: 'Repair approved',
        description: job.technicianName.trim().isEmpty
            ? details
            : '$details • ${job.technicianName}',
        type: 'repairApproved',
        dateTime: job.completedAt!,
      );
    }
  }

  String _inspectionDetails(WorkshopInspection inspection) {
    final person = inspection.inspectionType ==
                WorkshopInspectionType.driverDailyInspection
            ? inspection.driverName
            : inspection.technicianName;
    final base = '${inspection.inspectionNumber} • ${inspection.registration}';

    return person == null || person.trim().isEmpty
        ? base
        : '$base • $person';
  }
}
