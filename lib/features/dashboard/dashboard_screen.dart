import 'dart:async';

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
import 'services/dashboard_refresh_controller.dart';
import '../../shared/widgets/app_page_scaffold.dart';
import 'widgets/dashboard_hero_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    this.dashboardService,
    this.refreshInterval = const Duration(seconds: 60),
  });

  final DashboardService? dashboardService;
  final Duration refreshInterval;

  @override
  Widget build(BuildContext context) {
    return ProtectedScreen(
      allow: (_) => true,
      child: _DashboardContent(
        dashboardService: dashboardService,
        refreshInterval: refreshInterval,
      ),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent({
    this.dashboardService,
    required this.refreshInterval,
  });

  final DashboardService? dashboardService;
  final Duration refreshInterval;

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent>
    with WidgetsBindingObserver {
  late final DashboardService _dashboardService;
  DashboardRefreshController? _refreshController;
  DashboardSummary? _summary;
  Object? _initialLoadError;

  @override
  void initState() {
    super.initState();

    _dashboardService = widget.dashboardService ?? DashboardService();
    WidgetsBinding.instance.addObserver(this);

    if (PermissionService.instance.canViewKpis) {
      _refreshController = DashboardRefreshController(
        loadSummary: _dashboardService.loadSummary,
        onData: _setSummary,
        onInitialError: _setInitialLoadError,
        interval: widget.refreshInterval,
      )..startPeriodicRefresh();
      unawaited(_refreshController!.loadInitial());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final active = state == AppLifecycleState.resumed;
    _refreshController?.setActive(active);
    if (active) {
      unawaited(_refreshDashboard());
    }
  }

  void _setSummary(DashboardSummary summary) {
    if (!mounted) {
      return;
    }
    setState(() {
      _summary = summary;
      _initialLoadError = null;
    });
  }

  void _setInitialLoadError(Object error) {
    if (!mounted) {
      return;
    }
    setState(() {
      _initialLoadError = error;
    });
  }

  Future<void> _refreshDashboard() async {
    final controller = _refreshController;
    if (controller == null) {
      return;
    }
    await controller.refresh();
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
      customHeader: width >= 960
          ? DashboardHeroHeader(
              onRefresh: _refreshDashboard,
              onLogout: _logout,
              showBrand: false,
              showLogout: false,
              showIdentity: true,
              showRefresh: false,
            )
          : const SizedBox.shrink(),
      child: dashboardRole == DashboardRole.driver
          ? const DriverDashboard()
          : dashboardRole == DashboardRole.technician
          ? const TechnicianDashboard()
          : _buildFleetDashboard(dashboardRole),
    );
  }

  Widget _buildFleetDashboard(DashboardRole dashboardRole) {
    final summary = _summary;
    if (summary == null) {
      if (_initialLoadError != null) {
        return AppErrorState(
          title: 'Unable to load dashboard',
          message: 'Please try again.',
          onRetry: _refreshDashboard,
        );
      }
      return const AppLoadingState(label: 'Loading dashboard...');
    }

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
  }
}
