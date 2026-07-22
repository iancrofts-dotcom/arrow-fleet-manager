class FleetDashboardStats {
  final int totalVehicles;
  final int activeVehicles;

  final int totalDrivers;
  final int activeDrivers;

  final int assignedVehicles;
  final int unassignedVehicles;

  final int assignedDrivers;
  final int availableDrivers;

  const FleetDashboardStats({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.totalDrivers,
    required this.activeDrivers,
    required this.assignedVehicles,
    required this.unassignedVehicles,
    required this.assignedDrivers,
    required this.availableDrivers,
  });
}