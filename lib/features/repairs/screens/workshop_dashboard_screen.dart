import 'package:flutter/material.dart';

import '../models/repair.dart';
import '../repositories/repair_repository.dart';
import '../widgets/repair_card.dart';
import '../widgets/workshop_summary_card.dart';
import 'repair_details_screen.dart';
import '../models/workshop_summary.dart';
import '../models/repair_trend.dart';
import '../widgets/workshop_analytics_card.dart';

class WorkshopDashboardScreen extends StatefulWidget {
  const WorkshopDashboardScreen({
    super.key,
  });

  @override
  State<WorkshopDashboardScreen> createState() =>
      _WorkshopDashboardScreenState();
}

class _WorkshopDashboardScreenState
    extends State<WorkshopDashboardScreen> {
  final RepairRepository _repairRepository =
      RepairRepository();

  late Future<List<Repair>> repairsFuture;
late Future<WorkshopSummary> summaryFuture;
late Future<List<RepairTrend>> trendsFuture;

  @override
  void initState() {
    super.initState();
    loadRepairs();
  }

 void loadRepairs() {
  repairsFuture =
      _repairRepository.getOpenRepairs();

  summaryFuture =
      _repairRepository.getWorkshopSummary();

  trendsFuture =
      _repairRepository.getWeeklyRepairTrends();
}

  Future<void> refreshRepairs() async {
    setState(() {
      loadRepairs();
    });
  }

  Future<void> refresh() async {
    await refreshRepairs();
  }

  void addRepair() {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Manual repair creation will be added in Sprint 9.5.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workshop Dashboard',
        ),
      ),
      floatingActionButton:
          FloatingActionButton.extended(
        onPressed: addRepair,
        icon: const Icon(Icons.build),
        label: const Text(
          'New Repair',
        ),
      ),
      body: FutureBuilder<List<Repair>>(
        future: repairsFuture,
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          final repairs =
              snapshot.data ?? [];

          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding:
                  const EdgeInsets.all(12),
              children: [
                FutureBuilder<WorkshopSummary>(
  future: summaryFuture,
  builder: (context, snapshot) {
    final summary =
        snapshot.data ?? WorkshopSummary.empty();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: WorkshopSummaryCard(
                title: 'Open Repairs',
                value: '${summary.openRepairs}',
                icon: Icons.build,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WorkshopSummaryCard(
                title: 'High Priority',
                value: '${summary.highPriority}',
                icon: Icons.priority_high,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: WorkshopSummaryCard(
                title: 'Overdue',
                value: '${summary.overdueRepairs}',
                icon: Icons.schedule,
                color: Colors.deepOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: WorkshopSummaryCard(
                title: 'Completed',
                value: '${summary.completedThisWeek}',
                icon: Icons.check_circle,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  },
),
                const SizedBox(height: 12),
const SizedBox(height: 20),

FutureBuilder<List<RepairTrend>>(
  future: trendsFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState ==
        ConnectionState.waiting) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (snapshot.hasError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Unable to load repair trends.',
          ),
        ),
      );
    }

    return WorkshopAnalyticsCard(
      trends: snapshot.data ?? const [],
    );
  },
),

const SizedBox(height: 20),
                if (repairs.isEmpty)
                  const Padding(
                    padding:
                        EdgeInsets.only(
                      top: 60,
                    ),
                    child: Center(
                      child: Text(
                        'No open repairs found.\nCreate a repair from a failed inspection.',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                        ),
                      ),
                    ),
                  )
                else
                  ...repairs.map(
                    (repair) {
                                            return RepairCard(
                        repair: repair,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  RepairDetailsScreen(
                                repair: repair,
                              ),
                            ),
                          );

                          if (!mounted) {
                            return;
                          }

                          await refreshRepairs();
                        },
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}