import 'package:flutter/material.dart';

import '../../../auth/screens/my_account_screen.dart';
import '../../../auth/services/auth_service.dart';
import '../../../auth/services/permission_service.dart';
import '../../../drivers/services/driver_assignment_service.dart';
import '../../../inspections/inspection_screen.dart';
import '../../../vehicles/models/vehicle.dart';

class DriverDashboard extends StatelessWidget {
  const DriverDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;

    if (!permissions.isDriver) {
      return const Center(child: Text('Access denied.'));
    }

    final driverId = AuthService.instance.currentDriverId;

    return FutureBuilder<Vehicle?>(
      future: driverId == null
          ? Future<Vehicle?>.value()
          : DriverAssignmentService().getAssignedVehicle(driverId),
      builder: (context, snapshot) {
        final vehicle = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Driver Home',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            const Text('Your vehicle, daily walkaround, and account.'),
            const SizedBox(height: 24),
            _DriverActionCard(
              icon: Icons.local_shipping_outlined,
              title: 'My Vehicle',
              subtitle: loading
                  ? 'Loading assigned vehicle...'
                  : vehicle == null
                      ? 'No vehicle is currently assigned'
                      : '${vehicle.registration} • ${vehicle.make} ${vehicle.model}',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const _MyAssignedVehicleScreen(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _DriverActionCard(
              icon: Icons.fact_check_outlined,
              title: 'Daily Inspection',
              subtitle: vehicle == null
                  ? 'An assigned vehicle is required'
                  : 'Complete today\'s vehicle walkaround',
              onTap: vehicle == null
                  ? null
                  : () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InspectionScreen(
                            assignedVehicle: vehicle,
                            assignedDriverName:
                                AuthService.instance.currentUser?.username,
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 12),
            _DriverActionCard(
              icon: Icons.person_outline,
              title: 'My Account',
              subtitle: 'View your signed-in account',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MyAccountScreen(),
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
  const _MyAssignedVehicleScreen();

  @override
  Widget build(BuildContext context) {
    final driverId = AuthService.instance.currentDriverId;

    if (!PermissionService.instance.canViewAssignedVehicle || driverId == null) {
      return const _DriverAccessDenied(message: 'No driver account is linked.');
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Vehicle')),
      body: FutureBuilder<Vehicle?>(
        future: DriverAssignmentService().getAssignedVehicle(driverId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final vehicle = snapshot.data;
          if (vehicle == null) {
            return const Center(child: Text('No vehicle is currently assigned to you.'));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _VehicleDetailCard(label: 'Registration', value: vehicle.registration),
              _VehicleDetailCard(label: 'Fleet Number', value: vehicle.fleetNumber),
              _VehicleDetailCard(label: 'Vehicle', value: '${vehicle.make} ${vehicle.model}'),
              _VehicleDetailCard(label: 'Year', value: vehicle.year.toString()),
            ],
          );
        },
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
    return Card(
      child: ListTile(
        enabled: onTap != null,
        leading: Icon(icon),
        title: Text(title),
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
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message, textAlign: TextAlign.center))),
    );
  }
}
