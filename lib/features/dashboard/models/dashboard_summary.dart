class DashboardActivity {
  final String title;
  final String subtitle;
  final DateTime date;

  const DashboardActivity({
    required this.title,
    required this.subtitle,
    required this.date,
  });
}

class DashboardSummary {
  final int vehicles;
  final int activeVehicles;
  final int inactiveVehicles;

  final int drivers;
  final int inspections;
  final int defects;

  final int fleetHealth;

  final int motDue;
  final int serviceDue;
  final int overdue;

  final List<DashboardActivity> recentActivity;

  const DashboardSummary({
    required this.vehicles,
    required this.activeVehicles,
    required this.inactiveVehicles,
    required this.drivers,
    required this.inspections,
    required this.defects,
    required this.fleetHealth,
    required this.motDue,
    required this.serviceDue,
    required this.overdue,
    required this.recentActivity,
  });
}