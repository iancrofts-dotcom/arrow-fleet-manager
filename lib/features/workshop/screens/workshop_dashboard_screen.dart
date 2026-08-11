import 'package:flutter/material.dart';

import '../models/workshop_dashboard_data.dart';
import '../repositories/workshop_repository.dart';
import '../services/workshop_dashboard_service.dart';
import '../widgets/recent_activity_card.dart';
import '../widgets/workshop_action_button.dart';
import '../widgets/workshop_stat_card.dart';
import 'inspection_wizard/inspection_wizard_screen.dart';
import 'workshop_inspection_screen.dart';

class WorkshopDashboardScreen extends StatelessWidget {
  const WorkshopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboardService = WorkshopDashboardService(
      WorkshopRepository(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Image.asset(
                'assets/images/arrow_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 16),
            const Text('Arrow Fleet Manager\nWorkshop'),
          ],
        ),
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

          return LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth > 1280
                  ? 1280.0
                  : constraints.maxWidth;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workshop overview',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Manage inspections, repairs and today’s workload.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 28),
                        const _SectionHeader(
                          title: 'Quick actions',
                          subtitle: 'Start or manage workshop work',
                        ),
                        const SizedBox(height: 16),
                        _DashboardGrid(
                          columns: _actionColumns(contentWidth),
                          itemExtent: 148,
                          children: [
                            WorkshopActionButton(
                              title: 'New Inspection',
                              icon: Icons.add_task_rounded,
                              color: Colors.green,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const InspectionWizardScreen(),
                                  ),
                                );
                              },
                            ),
                            WorkshopActionButton(
                              title: 'Inspections',
                              icon: Icons.assignment_rounded,
                              color: Colors.indigo,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const WorkshopInspectionScreen(),
                                  ),
                                );
                              },
                            ),
                            WorkshopActionButton(
                              title: 'Repairs',
                              icon: Icons.build_circle_outlined,
                              color: Colors.orange,
                              onPressed: () {},
                            ),
                            WorkshopActionButton(
                              title: 'Workshop Calendar',
                              icon: Icons.calendar_month_rounded,
                              color: Colors.teal,
                              onPressed: () {},
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        const _SectionHeader(
                          title: 'Workshop KPIs',
                          subtitle: 'Current workload at a glance',
                        ),
                        const SizedBox(height: 16),
                        _DashboardGrid(
                          columns: _kpiColumns(contentWidth),
                          itemExtent: 184,
                          children: [
                            WorkshopStatCard(
                              title: "Today's Jobs",
                              value: dashboard.openInspections.toString(),
                              subtitle: 'Inspections in progress',
                              icon: Icons.today_rounded,
                              color: Colors.indigo,
                            ),
                            WorkshopStatCard(
                              title: 'Open Repairs',
                              value: dashboard.repairsRequired.toString(),
                              subtitle: 'Repair work required',
                              icon: Icons.handyman_rounded,
                              color: Colors.orange,
                            ),
                            WorkshopStatCard(
                              title: 'Awaiting Approval',
                              value: dashboard.criticalFailures.toString(),
                              subtitle: 'Critical issues to review',
                              icon: Icons.pending_actions_rounded,
                              color: Colors.deepOrange,
                            ),
                            WorkshopStatCard(
                              title: 'Completed Today',
                              value: dashboard.completedToday.toString(),
                              subtitle: 'Inspections completed',
                              icon: Icons.task_alt_rounded,
                              color: Colors.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 36),
                        const _SectionHeader(
                          title: 'Recent Workshop Activity',
                          subtitle: 'Latest updates from the workshop',
                        ),
                        const SizedBox(height: 16),
                        const RecentActivityCard(
                          icon: Icons.info_outline_rounded,
                          iconColor: Colors.blue,
                          title: 'Workshop ready',
                          subtitle: 'Live dashboard connected',
                          time: 'Now',
                        ),
                        const SizedBox(height: 36),
                        const _SectionHeader(
                          title: 'More workshop tools',
                          subtitle: 'Additional existing workshop actions',
                        ),
                        const SizedBox(height: 16),
                        _DashboardGrid(
                          columns: _actionColumns(contentWidth),
                          itemExtent: 148,
                          children: [
                            WorkshopActionButton(
                              title: 'Inspection Templates',
                              icon: Icons.fact_check_rounded,
                              color: Colors.blue,
                              onPressed: () {},
                            ),
                            WorkshopActionButton(
                              title: 'Reports',
                              icon: Icons.picture_as_pdf_rounded,
                              color: Colors.red,
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  int _actionColumns(double width) {
    if (width >= 1000) return 4;
    if (width >= 640) return 2;
    return 1;
  }

  int _kpiColumns(double width) {
    if (width >= 1100) return 4;
    if (width >= 640) return 2;
    return 1;
  }
}

class _DashboardGrid extends StatelessWidget {
  final int columns;
  final double itemExtent;
  final List<Widget> children;

  const _DashboardGrid({
    required this.columns,
    required this.itemExtent,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: columns,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      mainAxisExtent: itemExtent,
      children: children,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
