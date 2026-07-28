class WorkshopSummary {
  final int openRepairs;
  final int highPriority;
  final int overdueRepairs;
  final int completedThisWeek;

  const WorkshopSummary({
    required this.openRepairs,
    required this.highPriority,
    required this.overdueRepairs,
    required this.completedThisWeek,
  });

  factory WorkshopSummary.empty() {
    return const WorkshopSummary(
      openRepairs: 0,
      highPriority: 0,
      overdueRepairs: 0,
      completedThisWeek: 0,
    );
  }

  WorkshopSummary copyWith({
    int? openRepairs,
    int? highPriority,
    int? overdueRepairs,
    int? completedThisWeek,
  }) {
    return WorkshopSummary(
      openRepairs:
          openRepairs ?? this.openRepairs,
      highPriority:
          highPriority ?? this.highPriority,
      overdueRepairs:
          overdueRepairs ??
              this.overdueRepairs,
      completedThisWeek:
          completedThisWeek ??
              this.completedThisWeek,
    );
  }

  @override
  String toString() {
    return 'WorkshopSummary('
        'openRepairs: $openRepairs, '
        'highPriority: $highPriority, '
        'overdueRepairs: $overdueRepairs, '
        'completedThisWeek: $completedThisWeek'
        ')';
  }
}