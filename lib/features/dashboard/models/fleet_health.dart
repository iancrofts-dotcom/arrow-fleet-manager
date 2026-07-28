import 'package:flutter/material.dart';

enum FleetHealthStatus {
  excellent,
  good,
  fair,
  poor,
  critical,
}

class FleetHealth {
  final double score;
  final FleetHealthStatus status;
  final int healthyVehicles;
  final int warningVehicles;
  final int criticalVehicles;

  const FleetHealth({
    required this.score,
    required this.status,
    required this.healthyVehicles,
    required this.warningVehicles,
    required this.criticalVehicles,
  });

  Color get colour {
    switch (status) {
      case FleetHealthStatus.excellent:
        return Colors.green;

      case FleetHealthStatus.good:
        return Colors.lightGreen;

      case FleetHealthStatus.fair:
        return Colors.orange;

      case FleetHealthStatus.poor:
        return Colors.deepOrange;

      case FleetHealthStatus.critical:
        return Colors.red;
    }
  }

  String get label {
    switch (status) {
      case FleetHealthStatus.excellent:
        return "Excellent";

      case FleetHealthStatus.good:
        return "Good";

      case FleetHealthStatus.fair:
        return "Fair";

      case FleetHealthStatus.poor:
        return "Poor";

      case FleetHealthStatus.critical:
        return "Critical";
    }
  }

  bool get isHealthy => score >= 90;

  bool get needsAttention => score < 75;

  String get formattedScore => "${score.toStringAsFixed(0)}%";

  factory FleetHealth.empty() {
    return const FleetHealth(
      score: 100,
      status: FleetHealthStatus.excellent,
      healthyVehicles: 0,
      warningVehicles: 0,
      criticalVehicles: 0,
    );
  }
}