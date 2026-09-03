import 'package:flutter/material.dart';

import '../../../core/navigation/dashboard_navigation.dart';
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

    final items = <(String, int, IconData)>[
      ('Open Inspections', data.openInspections, Icons.assignment_outlined),
      ('Awaiting Sign-off', data.awaitingSignOff, Icons.fact_check_outlined),
      ('Repairs Outstanding', data.repairsOutstanding, Icons.build_outlined),
      ('Critical Defects', data.criticalFailures, Icons.warning_amber_outlined),
      ('Completed Today', data.completedToday, Icons.check_circle_outline),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workshop',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Overview of workshop activity and workload.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (PermissionService.instance.canAccessWorkshop)
              TextButton.icon(
                onPressed: () => DashboardNavigation.openWorkshop(context),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('View workshop'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 960
                ? 5
                : constraints.maxWidth >= 600
                ? 3
                : 2;
            const spacing = 12.0;
            final tileWidth =
                (constraints.maxWidth - ((columns - 1) * spacing)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: items
                  .map(
                    (item) => SizedBox(
                      width: tileWidth,
                      height: constraints.maxWidth >= 960 ? 152 : 144,
                      child: Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  item.$3,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${item.$2}',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.$1,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
