enum DashboardKpiTrend {
  up,
  down,
  stable,
}

class DashboardKpi {
  const DashboardKpi({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.trend,
  });

  final String title;
  final String value;
  final String subtitle;
  final String icon;
  final DashboardKpiTrend trend;

  DashboardKpi copyWith({
    String? title,
    String? value,
    String? subtitle,
    String? icon,
    DashboardKpiTrend? trend,
  }) {
    return DashboardKpi(
      title: title ?? this.title,
      value: value ?? this.value,
      subtitle: subtitle ?? this.subtitle,
      icon: icon ?? this.icon,
      trend: trend ?? this.trend,
    );
  }
}