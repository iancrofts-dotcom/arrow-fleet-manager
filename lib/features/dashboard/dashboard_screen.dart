import 'package:flutter/material.dart';

import '../history/inspection_history_screen.dart';
import '../inspections/inspection_screen.dart';
import '../vehicles/screens/vehicle_list_screen.dart';

import 'models/dashboard_summary.dart';
import 'services/dashboard_service.dart';

import 'widgets/compliance_summary_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/fleet_health_card.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/section_header.dart';
import 'widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardService _dashboardService;
  late Future<DashboardSummary> summaryFuture;

  @override
  void initState() {
    super.initState();

    _dashboardService = DashboardService();
    summaryFuture = _dashboardService.loadSummary();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      summaryFuture = _dashboardService.loadSummary();
    });

    await summaryFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Arrow Fleet Manager"),
      ),
      body: FutureBuilder<DashboardSummary>(
        future: summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading dashboard:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          final summary = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DashboardHeader(),

                  const SizedBox(height: 30),

                  const SectionHeader(
                    title: "Fleet Overview",
                  ),

                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      StatCard(
                        title: "Vehicles",
                        value: summary.vehicles.toString(),
                        icon: Icons.local_shipping,
                      ),
                      StatCard(
                        title: "Drivers",
                        value: summary.drivers.toString(),
                        icon: Icons.person,
                      ),
                      StatCard(
                        title: "Inspections",
                        value: summary.inspections.toString(),
                        icon: Icons.assignment,
                      ),
                      StatCard(
                        title: "Defects",
                        value: summary.defects.toString(),
                        icon: Icons.warning_amber,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                 FleetHealthCard(
  healthScore: summary.fleetHealth,
),

                  const SizedBox(height: 30),

                  ComplianceSummaryCard(
  motDue: summary.motDue,
  serviceDue: summary.serviceDue,
  overdue: summary.overdue,
),

                  const SizedBox(height: 30),

                  Text(
                    "Quick Actions",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.local_shipping),
                        label: const Text("Fleet Vehicles"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const VehicleListScreen(),
                            ),
                          );
                        },
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.assignment),
                        label: const Text("New Inspection"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const InspectionScreen(),
                            ),
                          );
                        },
                      ),
                      FilledButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text("Inspection History"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const InspectionHistoryScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  RecentActivityCard(
  activities: summary.recentActivity,
),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}