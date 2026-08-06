class WorkshopDashboardData {
  final int openInspections;
  final int completedToday;
  final int criticalFailures;
  final int repairsRequired;

  const WorkshopDashboardData({
    required this.openInspections,
    required this.completedToday,
    required this.criticalFailures,
    required this.repairsRequired,
  });

  factory WorkshopDashboardData.empty() {
    return const WorkshopDashboardData(
      openInspections: 0,
      completedToday: 0,
      criticalFailures: 0,
      repairsRequired: 0,
    );
  }
}