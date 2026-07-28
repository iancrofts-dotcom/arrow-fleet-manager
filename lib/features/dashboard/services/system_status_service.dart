import '../models/system_status.dart';

class SystemStatusService {
  const SystemStatusService();

  Future<List<SystemStatus>> getSystemStatus() async {
    // Simulate a short delay while loading status information.
    await Future.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();

    return [
      SystemStatus(
        name: 'Database',
        status: SystemServiceStatus.healthy,
        lastChecked: now,
      ),
      SystemStatus(
        name: 'Authentication',
        status: SystemServiceStatus.healthy,
        lastChecked: now,
      ),
      SystemStatus(
        name: 'Vehicle Service',
        status: SystemServiceStatus.healthy,
        lastChecked: now,
      ),
      SystemStatus(
        name: 'Driver Service',
        status: SystemServiceStatus.healthy,
        lastChecked: now,
      ),
      SystemStatus(
        name: 'Maintenance',
        status: SystemServiceStatus.healthy,
        lastChecked: now,
      ),
      SystemStatus(
        name: 'Documents',
        status: SystemServiceStatus.healthy,
        lastChecked: now,
      ),
    ];
  }
}