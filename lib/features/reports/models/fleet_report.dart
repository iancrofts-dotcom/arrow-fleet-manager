class FleetReport {
  final DateTime generatedAt;

  final int vehicles;
  final int activeVehicles;
  final int inactiveVehicles;

  final int inspections;
  final int defects;

  final int motDue;
  final int serviceDue;
  final int overdue;

  final int fleetHealth;

  const FleetReport({
    required this.generatedAt,
    required this.vehicles,
    required this.activeVehicles,
    required this.inactiveVehicles,
    required this.inspections,
    required this.defects,
    required this.motDue,
    required this.serviceDue,
    required this.overdue,
    required this.fleetHealth,
  });
}