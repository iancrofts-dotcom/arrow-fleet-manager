import 'package:flutter/material.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../../auth/screens/user_management_screen.dart';
import '../../auth/services/permission_service.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../drivers/models/driver.dart';
import '../../drivers/screens/add_driver_screen.dart';
import '../../history/inspection_history_screen.dart';
import '../../inspections/inspection_screen.dart';
import '../../vehicles/models/vehicle.dart';
import '../../vehicles/screens/add_vehicle_screen.dart';
import '../widgets/quick_action_card.dart';
import '../../workshop/screens/workshop_dashboard_screen.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final permissions = PermissionService.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          'Access your most frequently used tools.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 20,
          runSpacing: 20,
          children: [
            // Fleet
            if (permissions.canViewVehicles)
              QuickActionCard(
                icon: Icons.local_shipping,
                title: 'Fleet',
                subtitle: permissions.canManageVehicles
                    ? 'Manage fleet vehicles'
                    : 'View fleet vehicles',
                onTap: () => DashboardNavigation.openFleet(context),
                
              ),

            // Drivers
            if (permissions.canViewDrivers)
              QuickActionCard(
                icon: Icons.badge,
                title: 'Drivers',
                subtitle: permissions.canManageDrivers
                    ? 'Manage drivers'
                    : 'View drivers',
                onTap: () => DashboardNavigation.openDrivers(context),
              ),

            // Users
            if (permissions.canManageUsers)
              QuickActionCard(
                icon: Icons.manage_accounts,
                title: 'Users',
                subtitle: 'Manage application users',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UserManagementScreen(),
                    ),
                  );
                },
              ),

            // Calendar
            if (permissions.canAccessCalendar)
              QuickActionCard(
                icon: Icons.calendar_month,
                title: 'Calendar',
                subtitle: 'Fleet calendar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CalendarScreen(),
                    ),
                  );
                },
              ),

            // Inspection
            if (permissions.canManageWorkshop)
              QuickActionCard(
                icon: Icons.assignment,
                title: 'Inspection',
                subtitle: 'Create inspection',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InspectionScreen(),
                    ),
                  );
                },
              ),

            // History
            if (permissions.canManageWorkshop)
              QuickActionCard(
                icon: Icons.history,
                title: 'History',
                subtitle: 'Inspection history',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InspectionHistoryScreen(),
                    ),
                  );
                },
              ),
// Workshop
if (permissions.canAccessWorkshop)
  QuickActionCard(
    icon: Icons.build,
    title: 'Workshop',
    subtitle: 'Workshop inspections & repairs',
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const WorkshopDashboardScreen(),
        ),
      );
    },
  ),
            // Reports
            if (permissions.canViewReports)
              QuickActionCard(
                icon: Icons.description,
                title: 'Reports',
                subtitle: 'Fleet reports',
                onTap: () => DashboardNavigation.openReports(context),
              ),

            // Add Vehicle
            if (permissions.canManageVehicles)
              QuickActionCard(
                icon: Icons.add_circle_outline,
                title: 'Add Vehicle',
                subtitle: 'Create vehicle',
                onTap: () async {
                  final vehicle = await Navigator.push<Vehicle>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddVehicleScreen(),
                    ),
                  );

                  if (vehicle == null || !context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${vehicle.registration} created successfully.',
                      ),
                    ),
                  );
                },
              ),

            // Add Driver
            if (permissions.canManageDrivers)
              QuickActionCard(
                icon: Icons.person_add_alt,
                title: 'Add Driver',
                subtitle: 'Create driver',
                onTap: () async {
                  final driver = await Navigator.push<Driver>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddDriverScreen(),
                    ),
                  );

                  if (driver == null || !context.mounted) {
                    return;
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${driver.fullName} created successfully.',
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}
