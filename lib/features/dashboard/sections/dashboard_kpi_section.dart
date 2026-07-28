import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../models/dashboard_kpi.dart';
import '../services/dashboard_kpi_service.dart';
import '../widgets/dashboard_kpi_card.dart';

class DashboardKpiSection extends StatefulWidget {
  const DashboardKpiSection({super.key});

  @override
  State<DashboardKpiSection> createState() =>
      _DashboardKpiSectionState();
}

class _DashboardKpiSectionState
    extends State<DashboardKpiSection> {
  late final DashboardKpiService _service;
  late Future<List<DashboardKpi>> _future;

  @override
  void initState() {
    super.initState();

    _service = DashboardKpiService();
    _future = _service.getKpis();
  }

  IconData _iconFor(String title) {
    switch (title) {
      case 'Fleet':
        return Icons.local_shipping;

      case 'Drivers':
        return Icons.people;

      case 'Compliance':
        return Icons.verified_user;

      case 'Maintenance':
        return Icons.build;

      default:
        return Icons.dashboard;
    }
  }

  String? _routeFor(String title) {
    switch (title) {
      case 'Fleet':
        return AppRouter.vehicles;

      case 'Drivers':
        return AppRouter.drivers;

      case 'Maintenance':
        return AppRouter.maintenance;

      case 'Compliance':
        // Temporary destination until a dedicated
        // compliance dashboard is available.
        return AppRouter.drivers;

      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DashboardKpi>>(
      future: _future,
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
              padding: const EdgeInsets.all(20),
              child: Text(
                'Unable to load dashboard KPIs\n\n${snapshot.error}',
              ),
            ),
          );
        }

        final kpis = snapshot.data ?? [];

        if (kpis.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int columns = 1;

            if (constraints.maxWidth >= 1200) {
              columns = 4;
            } else if (constraints.maxWidth >= 700) {
              columns = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(),
              itemCount: kpis.length,
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                final kpi = kpis[index];

                return DashboardKpiCard(
                  kpi: kpi,
                  icon: _iconFor(kpi.title),
                  routeName: _routeFor(kpi.title),
                );
              },
            );
          },
        );
      },
    );
  }
}