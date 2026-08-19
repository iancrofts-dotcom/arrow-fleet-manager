import '../models/inspection_item.dart';
import '../models/inspection_photo.dart';
import '../models/repair_job.dart';
import '../models/workshop_inspection.dart';
import '../repositories/inspection_photo_repository.dart';
import '../repositories/workshop_repository.dart';

/// Applies reporting filters and derives Workshop report summaries from
/// persisted Workshop records. It deliberately does not infer data that the
/// current models do not store (for example parts cost or review reasons).
class WorkshopReportingService {
  WorkshopReportingService({
    WorkshopRepository? repository,
    InspectionPhotoRepository? photoRepository,
  })  : _repository = repository ?? WorkshopRepository(),
        _photoRepository = photoRepository ?? InspectionPhotoRepository();

  final WorkshopRepository _repository;
  final InspectionPhotoRepository _photoRepository;

  Future<WorkshopReportSource> loadSource() async {
    final results = await Future.wait([
      _repository.getAllRepairJobs(),
      _repository.getAllInspections(),
    ]);
    return WorkshopReportSource(
      jobs: results[0] as List<RepairJob>,
      inspections: results[1] as List<WorkshopInspection>,
    );
  }

  List<RepairJob> filterJobs(
    Iterable<RepairJob> jobs,
    WorkshopReportFilter filter,
  ) {
    return jobs.where((job) {
      if (!_inRange(job.createdAt, filter)) return false;
      if (filter.vehicleId != null && job.vehicleId != filter.vehicleId) {
        return false;
      }
      if (filter.technicianId != null &&
          job.technicianId != filter.technicianId) {
        return false;
      }
      if (filter.status != null && job.status != filter.status) return false;
      if (filter.priority != null && job.priority != filter.priority) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<WorkshopInspection> filterInspections(
    Iterable<WorkshopInspection> inspections,
    WorkshopReportFilter filter,
  ) {
    return inspections.where((inspection) {
      if (!_inRange(inspection.dateStarted, filter)) return false;
      if (filter.vehicleId != null &&
          inspection.vehicleId != filter.vehicleId) {
        return false;
      }
      if (filter.templateId != null &&
          inspection.templateId != filter.templateId) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.dateStarted.compareTo(a.dateStarted));
  }

  TechnicianWorkSummary technicianSummary(
    List<RepairJob> jobs,
    String technicianId,
  ) {
    final matching = jobs.where((job) => job.technicianId == technicianId).toList();
    return TechnicianWorkSummary(
      technicianId: technicianId,
      jobs: matching,
      activeJobs: matching.where((job) =>
          job.status == RepairJobStatus.assigned ||
          job.status == RepairJobStatus.inProgress ||
          job.status == RepairJobStatus.awaitingParts).length,
      awaitingReview: matching
          .where((job) => job.status == RepairJobStatus.awaitingInspection)
          .length,
      completedJobs: matching
          .where((job) => job.status == RepairJobStatus.completed)
          .length,
      vehicleCount: matching.map((job) => job.vehicleId).toSet().length,
      actualHours: _sumHours(matching),
      actualCost: _sumActualCost(matching),
    );
  }

  WorkshopCostSummary costSummary(List<RepairJob> jobs) {
    final completed = jobs
        .where((job) => job.status == RepairJobStatus.completed)
        .length;
    final outstanding = jobs
        .where((job) => job.status != RepairJobStatus.completed &&
            job.status != RepairJobStatus.cancelled)
        .length;
    return WorkshopCostSummary(
      jobs: jobs,
      completedJobs: completed,
      outstandingJobs: outstanding,
      estimatedCost: jobs.fold(0.0, (sum, job) => sum + job.estimatedCost),
      actualCost: _sumActualCost(jobs),
      estimatedHours: jobs.fold(0.0, (sum, job) => sum + job.estimatedHours),
      actualHours: _sumHours(jobs),
      actualCostByVehicle: _groupCost(jobs, (job) => job.vehicleRegistration),
      actualCostByPriority: _groupCost(jobs, (job) => job.priority.name),
    );
  }

  VehicleWorkshopHistory vehicleHistory({
    required int vehicleId,
    required List<WorkshopInspection> inspections,
    required List<RepairJob> jobs,
    required Map<int, List<InspectionItem>> itemsByInspection,
  }) {
    final vehicleInspections = inspections
        .where((inspection) => inspection.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.dateStarted.compareTo(a.dateStarted));
    final vehicleJobs = jobs.where((job) => job.vehicleId == vehicleId).toList();
    final itemCount = vehicleInspections.fold<int>(0, (total, inspection) {
      return total +
          (itemsByInspection[inspection.id] ?? const <InspectionItem>[])
              .where((item) =>
                  item.status == InspectionItemStatus.fail || item.repairRequired)
              .length;
    });
    return VehicleWorkshopHistory(
      inspections: vehicleInspections,
      jobs: vehicleJobs,
      failedOrRepairRequiredItems: itemCount,
      completedJobs: vehicleJobs
          .where((job) => job.status == RepairJobStatus.completed)
          .length,
      outstandingJobs: vehicleJobs
          .where((job) => job.status != RepairJobStatus.completed &&
              job.status != RepairJobStatus.cancelled)
          .length,
      actualHours: _sumHours(vehicleJobs),
      actualCost: _sumActualCost(vehicleJobs),
    );
  }

  Future<InspectionReportData> loadInspectionReport(int inspectionId) async {
    final inspection = await _repository.getInspection(inspectionId);
    if (inspection == null) {
      throw StateError('Workshop inspection $inspectionId was not found.');
    }
    final results = await Future.wait([
      _repository.getInspectionItems(inspectionId),
      _repository.getRepairJobs(inspectionId),
      _photoRepository.getForInspection(inspectionId),
    ]);
    return InspectionReportData(
      inspection: inspection,
      items: results[0] as List<InspectionItem>,
      jobs: results[1] as List<RepairJob>,
      photos: results[2] as List<InspectionPhoto>,
    );
  }

  bool _inRange(DateTime value, WorkshopReportFilter filter) {
    final start = filter.start;
    final end = filter.end;
    if (start != null && value.isBefore(_startOfDay(start))) return false;
    if (end != null && value.isAfter(_endOfDay(end))) return false;
    return true;
  }

  static DateTime _startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _endOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  static double _sumHours(Iterable<RepairJob> jobs) =>
      jobs.fold(0.0, (sum, job) => sum + job.actualHours);
  static double _sumActualCost(Iterable<RepairJob> jobs) =>
      jobs.fold(0.0, (sum, job) => sum + job.actualCost);
  static Map<String, double> _groupCost(
    Iterable<RepairJob> jobs,
    String Function(RepairJob) keyOf,
  ) {
    final totals = <String, double>{};
    for (final job in jobs) {
      totals.update(keyOf(job), (value) => value + job.actualCost,
          ifAbsent: () => job.actualCost);
    }
    return totals;
  }
}

class WorkshopReportSource {
  const WorkshopReportSource({required this.jobs, required this.inspections});
  final List<RepairJob> jobs;
  final List<WorkshopInspection> inspections;
}

class WorkshopReportFilter {
  WorkshopReportFilter({
    this.start,
    this.end,
    this.vehicleId,
    this.technicianId,
    this.status,
    this.priority,
    this.templateId,
  }) : assert(start == null || end == null || !start.isAfter(end));
  final DateTime? start;
  final DateTime? end;
  final int? vehicleId;
  final String? technicianId;
  final RepairJobStatus? status;
  final RepairPriority? priority;
  final int? templateId;
}

class TechnicianWorkSummary {
  const TechnicianWorkSummary({required this.technicianId, required this.jobs, required this.activeJobs, required this.awaitingReview, required this.completedJobs, required this.vehicleCount, required this.actualHours, required this.actualCost});
  final String technicianId;
  final List<RepairJob> jobs;
  final int activeJobs;
  final int awaitingReview;
  final int completedJobs;
  final int vehicleCount;
  final double actualHours;
  final double actualCost;
}

class WorkshopCostSummary {
  const WorkshopCostSummary({required this.jobs, required this.completedJobs, required this.outstandingJobs, required this.estimatedCost, required this.actualCost, required this.estimatedHours, required this.actualHours, required this.actualCostByVehicle, required this.actualCostByPriority});
  final List<RepairJob> jobs;
  final int completedJobs;
  final int outstandingJobs;
  final double estimatedCost;
  final double actualCost;
  final double estimatedHours;
  final double actualHours;
  final Map<String, double> actualCostByVehicle;
  final Map<String, double> actualCostByPriority;
  double get costVariance => actualCost - estimatedCost;
}

class VehicleWorkshopHistory {
  const VehicleWorkshopHistory({required this.inspections, required this.jobs, required this.failedOrRepairRequiredItems, required this.completedJobs, required this.outstandingJobs, required this.actualHours, required this.actualCost});
  final List<WorkshopInspection> inspections;
  final List<RepairJob> jobs;
  final int failedOrRepairRequiredItems;
  final int completedJobs;
  final int outstandingJobs;
  final double actualHours;
  final double actualCost;
}

class InspectionReportData {
  const InspectionReportData({required this.inspection, required this.items, required this.jobs, required this.photos});
  final WorkshopInspection inspection;
  final List<InspectionItem> items;
  final List<RepairJob> jobs;
  final List<InspectionPhoto> photos;
}
