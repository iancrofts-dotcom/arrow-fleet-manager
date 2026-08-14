import 'package:flutter/material.dart';

import '../../auth/services/permission_service.dart';
import '../../workshop/models/workshop_dashboard_data.dart';

class WorkshopKpiSection extends StatelessWidget {
  const WorkshopKpiSection({super.key, required this.data});

  final WorkshopDashboardData data;

  @override
  Widget build(BuildContext context) {
    if (!PermissionService.instance.canViewKpis) {
      return const SizedBox.shrink();
    }

    final items = [
      ('Open Inspections', data.openInspections, Icons.assignment_outlined),
      ('Awaiting Sign-off', data.awaitingSignOff, Icons.fact_check_outlined),
      ('Repairs Outstanding', data.repairsOutstanding, Icons.build_outlined),
      ('Critical Defects', data.criticalFailures, Icons.warning_amber_outlined),
      ('Completed Today', data.completedToday, Icons.check_circle_outline),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workshop', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) => SizedBox(
            width: 210,
            child: Card(child: ListTile(
              leading: Icon(item.$3),
              title: Text(item.$1),
              trailing: Text('${item.$2}', style: Theme.of(context).textTheme.titleLarge),
            )),
          )).toList(),
        ),
      ],
    );
  }
}
