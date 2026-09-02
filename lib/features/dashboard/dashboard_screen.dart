import 'package:flutter/material.dart';

import '../auth/models/user_role.dart';
import '../auth/services/auth_service.dart';
import '../auth/services/permission_service.dart';
import '../auth/widgets/protected_screen.dart';

import 'builders/dashboard_router.dart';
import 'sections/role_sections/driver_dashboard.dart';
import 'sections/role_sections/technician_dashboard.dart';

import 'models/dashboard_summary.dart';
import 'models/dashboard_context.dart';
import 'services/dashboard_service.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import 'widgets/dashboard_hero_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ProtectedScreen(
      allow: (_) => true,
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> {
  late final DashboardService _dashboardService;

  Future<DashboardSummary>? summaryFuture;

  @override
  void initState() {
    super.initState();

    _dashboardService = DashboardService();

    if (PermissionService.instance.canViewKpis) {
      summaryFuture = _dashboardService.loadSummary();
    }
  }

  Future<void> _refreshDashboard() async {
    if (!PermissionService.instance.canViewKpis) {
      return;
    }

    setState(() {
      summaryFuture = _dashboardService.loadSummary();
    });

    await summaryFuture;
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
  }

  DashboardRole _getDashboardRole() {
    final currentUser = AuthService.instance.currentUser;

    switch (currentUser?.role) {
      case UserRole.admin:
        return DashboardRole.administrator;

      case UserRole.manager:
        return DashboardRole.fleetManager;

      case UserRole.workshop:
        return DashboardRole.workshopManager;

      case UserRole.technician:
        return DashboardRole.technician;

      case UserRole.driver:
        return DashboardRole.driver;

      case null:
        return DashboardRole.driver;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardRole = _getDashboardRole();
    final width = MediaQuery.sizeOf(context).width;

    return AppPageScaffold(
      title: 'Dashboard',
      subtitle: 'Fleet overview and operational status.',
      customHeader: DashboardHeroHeader(
        onRefresh: _refreshDashboard,
        onLogout: _logout,
        showBrand: false,
        showLogout: false,
        showIdentity: width >= 960,
      ),
      child: dashboardRole == DashboardRole.driver
          ? const DriverDashboard()
          : dashboardRole == DashboardRole.technician
          ? const TechnicianDashboard()
          : FutureBuilder<DashboardSummary>(
              future: summaryFuture!,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingState(label: 'Loading dashboard...');
                }

                if (snapshot.hasError) {
                  return AppErrorState(
                    title: 'Unable to load dashboard',
                    message: 'Please try again.',
                    onRetry: _refreshDashboard,
                  );
                }

                if (!snapshot.hasData) {
                  return const AppEmptyState(
                    icon: Icons.dashboard_outlined,
                    title: 'No dashboard data available',
                    message: 'Refresh to load the latest operational summary.',
                  );
                }

                final summary = snapshot.data!;

                final fleetHealth = _dashboardService.getFleetHealth(summary);

                final dashboardContext = DashboardContext(
                  summary: summary,
                  fleetHealth: fleetHealth,
                  onRefresh: _refreshDashboard,
                );

                return DashboardRouter.build(
                  role: dashboardRole,
                  context: dashboardContext,
                );
              },
            ),
    );
  }
}
