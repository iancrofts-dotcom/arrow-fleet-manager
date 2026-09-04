import '../../workshop/models/workshop_inspection.dart';
import '../../workshop/repositories/workshop_repository.dart';
import '../mappers/driver_daily_check_activity_mapper.dart';
import '../models/dashboard_activity.dart';

class DriverDailyCheckActivityService {
  DriverDailyCheckActivityService({WorkshopRepository? repository})
    : _repository = repository ?? WorkshopRepository();

  final WorkshopRepository _repository;
  final DriverDailyCheckActivityMapper _mapper =
      const DriverDailyCheckActivityMapper();

  Future<List<DashboardActivity>> getRecentActivities({
    List<WorkshopInspection>? inspections,
    int limit = 5,
  }) async {
    final persistedInspections =
        inspections ?? await _repository.getAllInspections();
    final activities =
        persistedInspections
            .where(
              (inspection) =>
                  inspection.inspectionType ==
                      WorkshopInspectionType.driverDailyInspection &&
                  inspection.dateCompleted != null,
            )
            .map(_mapper.toActivity)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return activities.take(limit).toList(growable: false);
  }
}
