import 'package:flutter/material.dart';

import '../../models/dashboard_context.dart';
import '../../widgets/dashboard_content.dart';

class WorkshopManagerDashboard extends StatelessWidget {
  const WorkshopManagerDashboard({
    super.key,
    required this.context,
  });

  final DashboardContext context;

  @override
  Widget build(BuildContext context) {
    return DashboardContent(
      context: this.context,
    );
  }
}