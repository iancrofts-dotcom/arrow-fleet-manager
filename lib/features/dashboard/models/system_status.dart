enum SystemServiceStatus {
  healthy,
  warning,
  error,
  offline,
}

class SystemStatus {
  const SystemStatus({
    required this.name,
    required this.status,
    this.message,
    this.lastChecked,
  });

  final String name;
  final SystemServiceStatus status;
  final String? message;
  final DateTime? lastChecked;

  bool get isHealthy => status == SystemServiceStatus.healthy;

  SystemStatus copyWith({
    String? name,
    SystemServiceStatus? status,
    String? message,
    DateTime? lastChecked,
  }) {
    return SystemStatus(
      name: name ?? this.name,
      status: status ?? this.status,
      message: message ?? this.message,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}