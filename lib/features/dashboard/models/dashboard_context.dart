import 'package:flutter/foundation.dart';

import 'dashboard_summary.dart';
import 'fleet_health.dart';

@immutable
class DashboardContext {
  const DashboardContext({
    required this.summary,
    required this.fleetHealth,
    required this.onRefresh,
  });

  /// Dashboard statistics and KPIs.
  final DashboardSummary summary;

  /// Overall fleet health information.
  final FleetHealth fleetHealth;

  /// Refresh callback supplied by DashboardScreen.
  final Future<void> Function() onRefresh;
}