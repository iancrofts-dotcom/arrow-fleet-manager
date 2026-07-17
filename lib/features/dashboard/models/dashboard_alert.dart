import 'package:flutter/material.dart';

enum DashboardAlertSeverity {
  info,
  warning,
  critical,
}

class DashboardAlert {
  const DashboardAlert({
    required this.title,
    required this.message,
    required this.date,
    required this.icon,
    required this.severity,
    this.route,
  });

  final String title;
  final String message;
  final DateTime date;
  final IconData icon;
  final DashboardAlertSeverity severity;

  /// Optional route or identifier for future navigation.
  final String? route;
}