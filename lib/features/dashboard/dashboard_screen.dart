import 'package:flutter/material.dart';

import '../auth/models/user_role.dart';
import '../auth/screens/login_screen.dart';
import '../auth/services/auth_service.dart';
import '../auth/services/permission_service.dart';

import 'builders/dashboard_router.dart';
import 'sections/role_sections/driver_dashboard.dart';
import 'sections/role_sections/technician_dashboard.dart';

import 'models/dashboard_summary.dart';
import 'models/dashboard_context.dart';
import 'services/dashboard_service.dart';
import '../../shared/widgets/app_page_scaffold.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
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

    return AppPageScaffold(
      title: 'Dashboard',
      subtitle: 'Fleet overview and operational status.',
      actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      child: dashboardRole == DashboardRole.driver
          ? const DriverDashboard()
          : dashboardRole == DashboardRole.technician
              ? const TechnicianDashboard()
          : FutureBuilder<DashboardSummary>(
        future: summaryFuture!,
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
                  'Error loading dashboard\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text('No dashboard data available'),
            );
          }

          final summary = snapshot.data!;

          final fleetHealth =
              _dashboardService.getFleetHealth(summary);

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
