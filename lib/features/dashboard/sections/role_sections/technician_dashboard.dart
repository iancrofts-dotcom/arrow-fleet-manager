import 'package:flutter/material.dart';

import '../../../workshop/screens/workshop_dashboard_screen.dart';
import '../../../auth/widgets/protected_screen.dart';
import '../../../../shared/widgets/app_page_scaffold.dart';

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SectionCard(
          title: 'Workshop operations',
          subtitle: 'View and update your assigned repair jobs.',
          child: FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProtectedScreen(
                  allow: (permissions) => permissions.canAccessWorkshop,
                  child: const WorkshopDashboardScreen(),
                ),
              ),
            ),
            icon: const Icon(Icons.handyman_outlined),
            label: const Text('Open My Repair Jobs'),
          ),
        ),
      ),
    );
  }
}
