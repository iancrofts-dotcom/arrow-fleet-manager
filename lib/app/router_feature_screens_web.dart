import 'package:flutter/material.dart';

export '../features/vehicles/screens/vehicle_list_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Dashboard')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Central dashboard metrics are still being migrated.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/vehicles'),
              child: const Text('Open Fleet'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _UnavailableScreen extends StatelessWidget {
  const _UnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'This feature is not yet available with the central web backend.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class UserManagementScreen extends _UnavailableScreen {
  const UserManagementScreen({super.key});
}

class CalendarScreen extends _UnavailableScreen {
  const CalendarScreen({super.key});
}

class ComplianceCentreScreen extends _UnavailableScreen {
  const ComplianceCentreScreen({super.key});
}

class DocumentListScreen extends _UnavailableScreen {
  const DocumentListScreen({super.key});
}

class DriverListScreen extends _UnavailableScreen {
  const DriverListScreen({super.key});
}

class ReportsScreen extends _UnavailableScreen {
  const ReportsScreen({super.key});
}

class WorkshopDashboardScreen extends _UnavailableScreen {
  const WorkshopDashboardScreen({super.key});
}
