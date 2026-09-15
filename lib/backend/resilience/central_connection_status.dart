import 'central_failure_kind.dart';

enum CentralConnectionState { unknown, online, degraded, offline }

class CentralConnectionStatus {
  const CentralConnectionStatus({
    required this.state,
    required this.lastCheckedAt,
    this.failureKind = CentralFailureKind.none,
    this.message,
  });

  const CentralConnectionStatus.unknown()
    : state = CentralConnectionState.unknown,
      lastCheckedAt = null,
      failureKind = CentralFailureKind.none,
      message = null;

  final CentralConnectionState state;
  final DateTime? lastCheckedAt;
  final CentralFailureKind failureKind;
  final String? message;

  bool get isOnline => state == CentralConnectionState.online;
  bool get isOffline => state == CentralConnectionState.offline;
  bool get isDegraded => state == CentralConnectionState.degraded;

  CentralConnectionStatus copyWith({
    CentralConnectionState? state,
    DateTime? lastCheckedAt,
    CentralFailureKind? failureKind,
    String? message,
    bool clearMessage = false,
  }) {
    return CentralConnectionStatus(
      state: state ?? this.state,
      lastCheckedAt: lastCheckedAt ?? this.lastCheckedAt,
      failureKind: failureKind ?? this.failureKind,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}
