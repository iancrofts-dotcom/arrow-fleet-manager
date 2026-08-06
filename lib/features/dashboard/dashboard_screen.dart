import 'package:flutter/material.dart';

import '../auth/models/user_role.dart';
import '../auth/screens/login_screen.dart';
import '../auth/services/auth_service.dart';

import 'builders/dashboard_router.dart';

import 'models/dashboard_summary.dart';
import 'models/dashboard_context.dart';
import 'services/dashboard_service.dart';

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

      case UserRole.driver:
        return DashboardRole.driver;

      case UserRole.viewer:
      default:
        // Viewer currently uses the Fleet Manager dashboard
        // until a dedicated ViewerDashboard is created.
        return DashboardRole.fleetManager;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arrow Fleet Manager'),
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
            role: _getDashboardRole(),
            context: dashboardContext,
          );
        },
      ),
    );
  }
}