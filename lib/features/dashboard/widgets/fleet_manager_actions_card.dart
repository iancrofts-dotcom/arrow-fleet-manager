import 'package:flutter/material.dart';

import '../../../app/router.dart';

class FleetManagerActionsCard extends StatelessWidget {
  const FleetManagerActionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
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

            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.vehicles);
                  },
                  icon: const Icon(Icons.directions_car),
                  label: const Text('Vehicles'),
                ),

                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.workshop),
                  icon: const Icon(Icons.build),
                  label: const Text('Workshop'),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.drivers);
                  },
                  icon: const Icon(Icons.people),
                  label: const Text('Drivers'),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.calendar);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Calendar'),
                ),

                FilledButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.reports);
                  },
                  icon: const Icon(Icons.assessment),
                  label: const Text('Reports'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              'Management shortcuts for frequently used fleet tools.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
