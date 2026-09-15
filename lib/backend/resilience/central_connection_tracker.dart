import 'package:flutter/foundation.dart';

import 'central_connection_status.dart';
import 'central_failure_kind.dart';

class CentralConnectionTracker extends ChangeNotifier {
  CentralConnectionTracker({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  CentralConnectionStatus _status = const CentralConnectionStatus.unknown();

  CentralConnectionStatus get status => _status;

  void recordSuccess() {
    _setStatus(
      CentralConnectionStatus(
        state: CentralConnectionState.online,
        lastCheckedAt: _now(),
      ),
    );
  }

  void recordFailure(CentralFailureKind failureKind, {String? message}) {
    final nextState = switch (failureKind) {
      CentralFailureKind.connectivity ||
      CentralFailureKind.timeout => CentralConnectionState.offline,
      CentralFailureKind.none => CentralConnectionState.online,
      CentralFailureKind.authentication ||
      CentralFailureKind.authorization ||
      CentralFailureKind.server ||
      CentralFailureKind.unknown => CentralConnectionState.degraded,
    };

    _setStatus(
      CentralConnectionStatus(
        state: nextState,
        lastCheckedAt: _now(),
        failureKind: failureKind,
        message: message,
      ),
    );
  }

  void reset() {
    _setStatus(const CentralConnectionStatus.unknown());
  }

  void _setStatus(CentralConnectionStatus next) {
    if (_sameStatus(_status, next)) {
      return;
    }
    _status = next;
    notifyListeners();
  }

  bool _sameStatus(
    CentralConnectionStatus left,
    CentralConnectionStatus right,
  ) {
    return left.state == right.state &&
        left.lastCheckedAt == right.lastCheckedAt &&
        left.failureKind == right.failureKind &&
        left.message == right.message;
  }
}
