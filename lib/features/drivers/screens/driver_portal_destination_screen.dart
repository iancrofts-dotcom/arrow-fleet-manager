import 'package:flutter/material.dart';

import '../../../config/backend_mode.dart';
import '../../auth/screens/my_account_screen.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/services/permission_service.dart';
import '../../auth/widgets/protected_screen.dart';
import '../../documents/screens/central_document_list_screen.dart';
import '../../inspections/inspection_screen.dart';
import '../../vehicles/models/vehicle.dart';
import '../../../shared/widgets/app_page_scaffold.dart';
import '../services/central_driver_workspace_service.dart';
import '../services/driver_assignment_service.dart';
import 'central_driver_account_screen.dart';
import 'central_driver_compliance_screen.dart';

enum DriverPortalDestination {
  vehicle,
  inspection,
  compliance,
  documents,
  profile,
}

class DriverPortalDestinationScreen extends StatelessWidget {
  const DriverPortalDestinationScreen({super.key, required this.destination});

  final DriverPortalDestination destination;

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.isDriver) {
      return const _DriverPortalMessage(
        title: 'Access Denied',
        message: 'This area is available only to Driver accounts.',
      );
    }

    switch (destination) {
      case DriverPortalDestination.vehicle:
        return const _AssignedVehicleLoader(openInspection: false);
      case DriverPortalDestination.inspection:
        return const _AssignedVehicleLoader(openInspection: true);
      case DriverPortalDestination.compliance:
        return _centralDriverPage(
          (driverId) => CentralDriverComplianceScreen(driverId: driverId),
          unavailableMessage:
              'Driver compliance is available when your central Driver account is linked.',
        );
      case DriverPortalDestination.documents:
        return _centralDriverPage(
          (driverId) => CentralDocumentListScreen(
            initialFilter: 'Driver',
            entityType: 'driver',
            entityId: driverId,
            ownerLabel: 'My Driver',
          ),
          unavailableMessage:
              'Driver documents are available when your central Driver account is linked.',
        );
      case DriverPortalDestination.profile:
        return ProtectedScreen(
          allow: (permissions) => permissions.canViewOwnAccount,
          child: BackendModeConfig.current == BackendMode.supabase
              ? const CentralDriverAccountScreen()
              : const MyAccountScreen(),
        );
    }
  }

  Widget _centralDriverPage(
    Widget Function(String driverId) builder, {
    required String unavailableMessage,
  }) {
    if (BackendModeConfig.current != BackendMode.supabase) {
      return _DriverPortalMessage(
        title: 'Unavailable',
        message: unavailableMessage,
      );
    }
    final driverId = AuthService.instance.currentBackendDriverId;
    if (driverId == null || driverId.trim().isEmpty) {
      return _DriverPortalMessage(
        title: 'Driver account not linked',
        message: unavailableMessage,
      );
    }
    return builder(driverId);
  }
}

class _AssignedVehicleLoader extends StatelessWidget {
  const _AssignedVehicleLoader({required this.openInspection});

  final bool openInspection;

  Future<Vehicle?> _loadVehicle() {
    final auth = AuthService.instance;
    if (BackendModeConfig.current == BackendMode.supabase) {
      final driverId = auth.currentBackendDriverId;
      if (driverId == null) return Future<Vehicle?>.value();
      return CentralDriverWorkspaceService().getAssignedVehicle(driverId);
    }

    final driverId = auth.currentDriverId;
    if (driverId == null) return Future<Vehicle?>.value();
    return DriverAssignmentService().getAssignedVehicle(driverId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Vehicle?>(
      future: _loadVehicle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(
            label: 'Loading your assigned vehicle...',
          );
        }
        if (snapshot.hasError) {
          return AppErrorState(message: '${snapshot.error}');
        }
        final vehicle = snapshot.data;
        if (vehicle == null) {
          return const _DriverPortalMessage(
            title: 'No vehicle assigned',
            message:
                'Contact your fleet manager to be assigned a vehicle before using this area.',
          );
        }
        if (openInspection) {
          return ProtectedScreen(
            allow: (permissions) => permissions.canPerformDailyInspection,
            child: InspectionScreen(
              assignedVehicle: vehicle,
              assignedDriverName: AuthService.instance.currentUser?.username,
            ),
          );
        }
        return ProtectedScreen(
          allow: (permissions) => permissions.canViewAssignedVehicle,
          child: _AssignedVehicleScreen(vehicle: vehicle),
        );
      },
    );
  }
}

class _AssignedVehicleScreen extends StatelessWidget {
  const _AssignedVehicleScreen({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'My Vehicle',
      subtitle: 'Your currently assigned vehicle.',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.registration,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${vehicle.make} ${vehicle.model}'),
                const SizedBox(height: 20),
                _detail('Fleet Number', vehicle.fleetNumber),
                _detail('Year', vehicle.year.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    final displayValue = value.trim().isEmpty ? 'Not recorded' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(displayValue)),
        ],
      ),
    );
  }
}

class _DriverPortalMessage extends StatelessWidget {
  const _DriverPortalMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: title,
      child: AppEmptyState(
        icon: Icons.info_outline,
        title: title,
        message: message,
      ),
    );
  }
}
