import 'package:flutter/material.dart';

import '../../../app/router.dart';

class FleetManagerActionsCard extends StatelessWidget {
  const FleetManagerActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.manage_accounts,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  'Fleet Manager Actions',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.vehicles,
                    );
                  },
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Vehicles'),
                ),

                FilledButton.icon(
  onPressed: () {
    Navigator.pushNamed(
      context,
      AppRouter.workshop,
    );
  },
  icon: const Icon(Icons.build),
  label: const Text('Workshop'),
),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.drivers,
                    );
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Drivers'),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.calendar,
                    );
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Calendar'),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.reports,
                    );
                  },
                  icon: const Icon(Icons.assessment),
                  label: const Text('Reports'),
                ),

                
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Quick access to fleet management tools. '
              'Additional modules will become active as they are implemented.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
