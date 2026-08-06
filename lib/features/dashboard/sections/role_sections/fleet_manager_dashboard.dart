import 'package:flutter/material.dart';

import '../../models/dashboard_context.dart';
import '../../widgets/dashboard_content.dart';
import '../../widgets/fleet_manager_actions_card.dart';

class FleetManagerDashboard extends StatelessWidget {
  const FleetManagerDashboard({
    super.key,
    required this.context,
  });

  final DashboardContext context;

  @override
  Widget build(BuildContext context) {
    return DashboardContent(
      context: this.context,
      children: const [
        FleetManagerActionsCard(),
      ],
    );
  }
}