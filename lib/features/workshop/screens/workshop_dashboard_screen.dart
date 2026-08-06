import 'package:flutter/material.dart';

import '../models/workshop_dashboard_data.dart';
import '../repositories/workshop_repository.dart';
import '../services/workshop_dashboard_service.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/workshop_action_button.dart';
import '../widgets/workshop_stat_card.dart';
import 'workshop_inspection_screen.dart';
import 'new_workshop_inspection_screen.dart';

class WorkshopDashboardScreen extends StatelessWidget {
  const WorkshopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardService = WorkshopDashboardService(
      WorkshopRepository(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workshop Dashboard'),
      ),
      body: FutureBuilder<WorkshopDashboardData>(
        future: dashboardService.loadDashboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load dashboard.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final dashboard =
              snapshot.data ?? WorkshopDashboardData.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Overview",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 16),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    WorkshopStatCard(
                      title: 'Open Inspections',
                      value: dashboard.openInspections.toString(),
                      icon: Icons.assignment,
                      color: Colors.orange,
                    ),
                    WorkshopStatCard(
                      title: 'Completed Today',
                      value: dashboard.completedToday.toString(),
                      icon: Icons.check_circle,
                      color: Colors.green,
                    ),
                    WorkshopStatCard(
                      title: 'Critical Failures',
                      value: dashboard.criticalFailures.toString(),
                      icon: Icons.warning,
                      color: Colors.red,
                    ),
                    WorkshopStatCard(
                      title: 'Repairs Required',
                      value: dashboard.repairsRequired.toString(),
                      icon: Icons.build,
                      color: Colors.blue,
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 12),

                WorkshopActionButton(
                  title: 'New Inspection',
                  icon: Icons.add_circle_outline,
                  color: Colors.green,
                  onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const NewWorkshopInspectionScreen(),
                    ),
                  );
                },
                ),

                const SizedBox(height: 12),

                WorkshopActionButton(
                  title: 'Inspection List',
                  icon: Icons.assignment,
                  color: Colors.indigo,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkshopInspectionScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                WorkshopActionButton(
                  title: 'Repair Jobs',
                  icon: Icons.build_circle,
                  color: Colors.orange,
                  onPressed: () {},
                ),

                const SizedBox(height: 12),

                WorkshopActionButton(
                  title: 'Inspection Templates',
                  icon: Icons.fact_check,
                  color: Colors.blue,
                  onPressed: () {},
                ),

                const SizedBox(height: 12),

                WorkshopActionButton(
                  title: 'Reports',
                  icon: Icons.picture_as_pdf,
                  color: Colors.red,
                  onPressed: () {},
                ),

                const SizedBox(height: 28),

                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),

                const SizedBox(height: 12),

                const RecentActivityCard(
                  icon: Icons.info,
                  iconColor: Colors.blue,
                  title: 'Workshop Ready',
                  subtitle: 'Live dashboard connected',
                  time: 'Now',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}