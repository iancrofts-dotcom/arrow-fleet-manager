import 'package:flutter/material.dart';

import '../../../workshop/screens/workshop_dashboard_screen.dart';

class TechnicianDashboard extends StatelessWidget {
  const TechnicianDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const WorkshopDashboardScreen(),
            ),
          ),
          icon: const Icon(Icons.handyman_outlined),
          label: const Text('Open My Repair Jobs'),
        ),
      ),
    );
  }
}
