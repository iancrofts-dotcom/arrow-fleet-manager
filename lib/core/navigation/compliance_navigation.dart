import 'package:flutter/material.dart';

import '../../features/auth/widgets/protected_screen.dart';
import '../../features/compliance/models/fleet_compliance_summary.dart';
import '../../features/drivers/screens/driver_compliance_screen.dart';
import '../../features/vehicles/screens/vehicle_details_screen.dart';
import '../../features/vehicles/services/vehicle_service.dart';

/// Opens Compliance Centre attention subjects using their persisted IDs only.
class ComplianceNavigation {
  ComplianceNavigation._();

  static Future<void> openAttention(
    BuildContext context,
    FleetComplianceAttentionItem item,
  ) async {
    switch (item.subjectType) {
      case FleetComplianceSubjectType.vehicle:
        final vehicle = await VehicleService().getVehicleById(item.subjectId);
        if (vehicle == null || !context.mounted) {
          return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtectedScreen(
              allow: (permissions) => permissions.canViewVehicles,
              child: VehicleDetailsScreen(vehicle: vehicle),
            ),
          ),
        );
        return;
      case FleetComplianceSubjectType.driver:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProtectedScreen(
              allow: (permissions) => permissions.canViewDrivers,
              child: DriverComplianceScreen(driverId: item.subjectId),
            ),
          ),
        );
        return;
    }
  }
}
