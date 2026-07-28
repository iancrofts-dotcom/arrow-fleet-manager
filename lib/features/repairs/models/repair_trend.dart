class RepairTrend {
  final String period;
  final int completed;
  final int opened;

  const RepairTrend({
    required this.period,
    required this.completed,
    required this.opened,
  });

  factory RepairTrend.empty(String period) {
    return RepairTrend(
      period: period,
      completed: 0,
      opened: 0,
    );
  }

  int get difference => completed - opened;

  @override
  String toString() {
    return 'RepairTrend('
        'period: $period, '
        'completed: $completed, '
        'opened: $opened'
        ')';
  }
}