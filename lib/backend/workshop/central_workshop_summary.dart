import 'backend_workshop_inspection.dart';
import 'backend_workshop_repair_job.dart';

class CentralWorkshopSummary {
  const CentralWorkshopSummary({
    required this.totalInspections,
    required this.openInspections,
    required this.completedInspections,
    required this.criticalFailures,
    required this.outstandingRepairs,
    required this.awaitingParts,
  });

  final int totalInspections;
  final int openInspections;
  final int completedInspections;
  final int criticalFailures;
  final int outstandingRepairs;
  final int awaitingParts;

  factory CentralWorkshopSummary.fromData({
    required Iterable<BackendWorkshopInspection> inspections,
    required Iterable<BackendWorkshopRepairJob> repairJobs,
  }) {
    final inspectionList = inspections.toList(growable: false);
    final repairList = repairJobs.toList(growable: false);
    return CentralWorkshopSummary(
      totalInspections: inspectionList.length,
      openInspections: inspectionList.where((item) => item.isOpen).length,
      completedInspections: inspectionList
          .where((item) => item.isCompleted)
          .length,
      criticalFailures: inspectionList.fold<int>(
        0,
        (total, item) => total + item.criticalFailures,
      ),
      outstandingRepairs: repairList.where((item) => item.isOutstanding).length,
      awaitingParts: repairList
          .where((item) => item.isOutstanding && item.partsRequired)
          .length,
    );
  }
}
