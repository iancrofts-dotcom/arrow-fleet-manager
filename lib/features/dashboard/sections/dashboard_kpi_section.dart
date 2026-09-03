import 'package:flutter/material.dart';

import '../../../app/router.dart';
import '../../../core/navigation/dashboard_navigation.dart';
import '../../auth/services/permission_service.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_kpi_service.dart';
import '../widgets/dashboard_kpi_card.dart';

class DashboardKpiSection extends StatelessWidget {
  const DashboardKpiSection({super.key, required this.summary});

  final DashboardSummary summary;

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
    final kpis = const DashboardKpiService().fromSummary(summary);

    return LayoutBuilder(
      builder: (context, constraints) {
        var columns = 2;
        if (constraints.maxWidth >= 960) {
          columns = 4;
        }
        final phone = constraints.maxWidth <= 480;

        return GridView.builder(
          key: const Key('dashboard-primary-kpi-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: kpis.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: phone ? 12 : 16,
            mainAxisSpacing: phone ? 12 : 16,
            mainAxisExtent: phone ? 168 : 208,
          ),
          itemBuilder: (context, index) {
            final kpi = kpis[index];
            return DashboardKpiCard(
              key: Key('dashboard-kpi-${kpi.title.toLowerCase()}'),
              kpi: kpi,
              icon: _iconFor(kpi.title),
              routeName: _routeFor(kpi.title),
              onTap: _onTapFor(context, kpi.title),
            );
          },
        );
      },
    );
  }
}
