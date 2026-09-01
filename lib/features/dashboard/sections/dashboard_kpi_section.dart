import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../../auth/services/permission_service.dart';
import '../models/dashboard_kpi.dart';
import '../services/dashboard_kpi_service.dart';
import '../widgets/dashboard_kpi_card.dart';
import '../../../shared/widgets/app_page_scaffold.dart';

class DashboardKpiSection extends StatefulWidget {
  const DashboardKpiSection({super.key});

  @override
  State<DashboardKpiSection> createState() => _DashboardKpiSectionState();
}

class _DashboardKpiSectionState extends State<DashboardKpiSection> {
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
        return PermissionService.instance.canViewVehicles
            ? AppRouter.vehicles
            : null;

      case 'Drivers':
        return PermissionService.instance.canViewDrivers
            ? AppRouter.drivers
            : null;

      case 'Maintenance':
        return null;

      case 'Compliance':
        return null;

      default:
        return null;
    }
  }

  VoidCallback? _onTapFor(BuildContext context, String title) {
    if (title == 'Maintenance' &&
        PermissionService.instance.canAccessWorkshop) {
      return () => DashboardNavigation.openWorkshop(context);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DashboardKpi>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingState(label: 'Loading dashboard metrics...');
        }

        if (snapshot.hasError) {
          return AppErrorState(
            title: 'Unable to load dashboard metrics',
            message: 'Please try again.',
            onRetry: () => setState(() => _future = _service.getKpis()),
          );
        }

        final kpis = snapshot.data ?? [];

        if (kpis.isEmpty) {
          return const SizedBox.shrink();
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            int columns = 1;

            if (constraints.maxWidth >= 1000) {
              columns = 4;
            } else if (constraints.maxWidth >= 640) {
              columns = 2;
            }

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: kpis.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                  onTap: _onTapFor(context, kpi.title),
                );
              },
            );
          },
        );
      },
    );
  }
}
