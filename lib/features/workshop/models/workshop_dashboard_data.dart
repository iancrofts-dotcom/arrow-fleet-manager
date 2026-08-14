class WorkshopDashboardData {
  final int openInspections;
  final int completedToday;
  final int criticalFailures;
  final int repairsRequired;

  // Workshop Manager operational KPIs.
  final int repairsOutstanding;
  final int awaitingParts;
  final int awaitingSignOff;

  const WorkshopDashboardData({
    required this.openInspections,
    required this.completedToday,
    required this.criticalFailures,
    required this.repairsRequired,
    this.repairsOutstanding = 0,
    this.awaitingParts = 0,
    this.awaitingSignOff = 0,
  });

  factory WorkshopDashboardData.empty() {
    return const WorkshopDashboardData(
      openInspections: 0,
      completedToday: 0,
      criticalFailures: 0,
      repairsRequired: 0,
      repairsOutstanding: 0,
      awaitingParts: 0,
      awaitingSignOff: 0,
    );
  }
}
