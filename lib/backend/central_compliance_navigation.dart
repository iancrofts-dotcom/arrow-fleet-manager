import 'package:flutter/material.dart';

import '../features/auth/widgets/protected_screen.dart';
import '../features/compliance/models/fleet_compliance_summary.dart';
import '../features/drivers/models/driver_identity.dart';
import '../features/drivers/screens/central_driver_details_screen.dart';
import '../features/drivers/services/driver_read_service.dart';
import '../features/vehicles/models/vehicle_identity.dart';
import '../features/vehicles/screens/vehicle_details_screen.dart';
import '../features/vehicles/services/vehicle_service.dart';

class CentralComplianceNavigation {
  const CentralComplianceNavigation._();

  static Future<void> openAttention(
    BuildContext context,
    FleetComplianceAttentionItem item,
  ) async {
    final id = item.centralSubjectId;
    if (id == null) return;
    switch (item.subjectType) {
      case FleetComplianceSubjectType.vehicle:
        final service = VehicleService.forConfiguredBackend();
        final vehicle = await service.getVehicle(VehicleIdentity.central(id));
        if (vehicle == null || !context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtectedScreen(
              allow: (permissions) => permissions.canViewVehicles,
              child: VehicleDetailsScreen(
                vehicle: vehicle,
                vehicleService: service,
              ),
            ),
          ),
        );
        return;
      case FleetComplianceSubjectType.driver:
        final driver = await DriverReadService.forConfiguredBackend().getDriver(
          DriverIdentity.central(id),
        );
        if (driver == null || !context.mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtectedScreen(
              allow: (permissions) => permissions.canViewDrivers,
              child: CentralDriverDetailsScreen(driver: driver),
            ),
          ),
        );
        return;
    }
  }
}
