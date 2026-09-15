import 'package:flutter/material.dart';

import '../models/dashboard_context.dart';
import 'executive_dashboard_content.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({
    super.key,
    required this.context,
    this.children = const [],
  });

  final DashboardContext context;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ExecutiveDashboardContent(
      dashboardContext: this.context,
      children: children,
    );
  }
}
