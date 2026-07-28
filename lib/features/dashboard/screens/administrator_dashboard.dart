import 'package:flutter/material.dart';

import '../models/dashboard_context.dart';
import '../sections/notification_section.dart';
import '../sections/recent_activity_section.dart';
import '../sections/system_status_section.dart';
import '../widgets/dashboard_content.dart';

class AdministratorDashboard extends StatelessWidget {
  const AdministratorDashboard({
    super.key,
    required this.context,
  });

  final DashboardContext context;

  @override
  Widget build(BuildContext context) {
    return DashboardContent(
      context: this.context,
      children: const [
        SystemStatusSection(),
        SizedBox(height: 24),
        NotificationSection(),
        SizedBox(height: 24),
        RecentActivitySection(),
      ],
    );
  }
}