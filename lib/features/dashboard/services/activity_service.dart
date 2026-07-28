import '../models/activity_item.dart';

class ActivityService {
  const ActivityService();

  Future<List<ActivityItem>> getRecentActivity() async {
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    return [
      ActivityItem(
        id: '1',
        title: 'Vehicle Added',
        description: 'Ford Transit BK24 XYZ added to the fleet.',
        type: ActivityType.vehicle,
        timestamp: now.subtract(const Duration(minutes: 8)),
      ),
      ActivityItem(
        id: '2',
        title: 'Driver Assigned',
        description: 'John Smith assigned to Mercedes Sprinter AB22 CDE.',
        type: ActivityType.driver,
        timestamp: now.subtract(const Duration(minutes: 20)),
      ),
      ActivityItem(
        id: '3',
        title: 'Maintenance Completed',
        description: 'Oil service completed for Vehicle LM56 NOP.',
        type: ActivityType.maintenance,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
      ActivityItem(
        id: '4',
        title: 'Inspection Submitted',
        description: 'Daily inspection completed for Vehicle XY12 ZZZ.',
        type: ActivityType.inspection,
        timestamp: now.subtract(const Duration(hours: 4)),
      ),
      ActivityItem(
        id: '5',
        title: 'Insurance Updated',
        description: 'Insurance renewed for Vehicle AB12 CDE.',
        type: ActivityType.compliance,
        timestamp: now.subtract(const Duration(days: 1)),
      ),
      ActivityItem(
        id: '6',
        title: 'System Backup',
        description: 'Automatic nightly database backup completed.',
        type: ActivityType.system,
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
      ),
    ];
  }
}