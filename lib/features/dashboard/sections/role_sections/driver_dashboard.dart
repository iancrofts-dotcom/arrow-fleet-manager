import 'package:flutter/material.dart';

import '../../../../app/router.dart';
import '../../../../config/backend_mode.dart';
import '../../../auth/screens/my_account_screen.dart';
import '../../../drivers/screens/central_driver_account_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/services/permission_service.dart';
import '../../../auth/widgets/protected_screen.dart';
import '../../../drivers/services/driver_assignment_service.dart';
import '../../../drivers/services/central_driver_workspace_service.dart';
import '../../../drivers/screens/central_driver_compliance_screen.dart';
import '../../../documents/screens/central_document_list_screen.dart';
import '../../../inspections/inspection_screen.dart';
import '../../../vehicles/models/vehicle.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;

    if (!permissions.isDriver) {
      return const Center(child: Text('Access denied.'));
    }

    final auth = AuthService.instance;
    final isCentral = BackendModeConfig.current == BackendMode.supabase;
    final driverId = auth.currentDriverId;
    final centralDriverId = auth.currentBackendDriverId;

    final Future<Vehicle?> assignedVehicleFuture;
    if (isCentral) {
      assignedVehicleFuture = centralDriverId == null
          ? Future<Vehicle?>.value()
          : CentralDriverWorkspaceService().getAssignedVehicle(centralDriverId);
    } else {
      assignedVehicleFuture = driverId == null
          ? Future<Vehicle?>.value()
          : DriverAssignmentService().getAssignedVehicle(driverId);
    }

    return FutureBuilder<Vehicle?>(
      future: assignedVehicleFuture,
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
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const AppEmptyState(
                icon: Icons.local_shipping_outlined,
                title: 'No vehicle assigned',
                message:
                    'Contact your fleet manager to be assigned a vehicle before completing a daily inspection.',
              ),
              const SizedBox(height: 20),
              if (centralDriverId != null) ...[
                _DriverActionCard(
                  icon: Icons.verified_user_outlined,
                  title: 'My Compliance',
                  subtitle:
                      'Update licence, CPC, medical, DBS and taxi licence',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CentralDriverComplianceScreen(
                        driverId: centralDriverId,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DriverActionCard(
                  icon: Icons.folder_shared_outlined,
                  title: 'My Documents',
                  subtitle: 'Upload and view your Driver documents',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CentralDocumentListScreen(
                        initialFilter: 'Driver',
                        entityType: 'driver',
                        entityId: centralDriverId,
                        ownerLabel: 'My Driver',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _DriverActionCard(
                icon: Icons.person_outline,
                title: 'My Account',
                subtitle: 'View your signed-in account',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProtectedScreen(
                      allow: (permissions) => permissions.canViewOwnAccount,
                      child: isCentral
                          ? const CentralDriverAccountScreen()
                          : const MyAccountScreen(),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Driver workspace',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Your assigned vehicle, daily inspection and account actions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            _DriverActionCard(
              icon: Icons.local_shipping_outlined,
              title: 'My Vehicle',
              subtitle:
                  '${vehicle.registration} • ${vehicle.make} ${vehicle.model}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProtectedScreen(
                    allow: (permissions) => permissions.canViewAssignedVehicle,
                    child: _MyAssignedVehicleScreen(vehicle: vehicle),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DriverActionCard(
              icon: Icons.fact_check_outlined,
              title: 'Daily Inspection',
              subtitle: 'Complete today\'s vehicle walkaround',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  settings: const RouteSettings(name: AppRouter.dashboard),
                  builder: (_) => ProtectedScreen(
                    allow: (permissions) =>
                        permissions.canPerformDailyInspection,
                    child: InspectionScreen(
                      assignedVehicle: vehicle,
                      assignedDriverName:
                          AuthService.instance.currentUser?.username,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (centralDriverId != null) ...[
              _DriverActionCard(
                icon: Icons.verified_user_outlined,
                title: 'My Compliance',
                subtitle: 'Update licence, CPC, medical, DBS and taxi licence',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CentralDriverComplianceScreen(
                      driverId: centralDriverId,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DriverActionCard(
                icon: Icons.folder_shared_outlined,
                title: 'My Documents',
                subtitle: 'Upload and view your Driver documents',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CentralDocumentListScreen(
                      initialFilter: 'Driver',
                      entityType: 'driver',
                      entityId: centralDriverId,
                      ownerLabel: 'My Driver',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _DriverActionCard(
              icon: Icons.person_outline,
              title: 'My Account',
              subtitle: 'View your signed-in account',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProtectedScreen(
                    allow: (permissions) => permissions.canViewOwnAccount,
                    child: isCentral
                        ? const CentralDriverAccountScreen()
                        : const MyAccountScreen(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MyAssignedVehicleScreen extends StatelessWidget {
  const _MyAssignedVehicleScreen({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canViewAssignedVehicle) {
      return const _DriverAccessDenied(message: 'No driver account is linked.');
    }

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
                  'Vehicle Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _VehicleDetailCard(
                  label: 'Registration',
                  value: vehicle.registration,
                ),
                _VehicleDetailCard(
                  label: 'Fleet Number',
                  value: vehicle.fleetNumber,
                ),
                _VehicleDetailCard(
                  label: 'Vehicle',
                  value: '${vehicle.make} ${vehicle.model}',
                ),
                _VehicleDetailCard(
                  label: 'Year',
                  value: vehicle.year.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverActionCard extends StatelessWidget {
  const _DriverActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        enabled: onTap != null,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: scheme.onPrimaryContainer),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _VehicleDetailCard extends StatelessWidget {
  const _VehicleDetailCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(title: Text(label), subtitle: Text(value)),
    );
  }
}

class _DriverAccessDenied extends StatelessWidget {
  const _DriverAccessDenied({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access Denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
