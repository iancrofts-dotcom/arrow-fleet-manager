/// Prevents overlapping report operations while ensuring the gate is released
/// after either completion or failure.
class ReportOperationGate {
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<bool> run(Future<void> Function() operation) async {
    if (_isRunning) return false;

    _isRunning = true;
    try {
      await operation();
      return true;
    } finally {
      _isRunning = false;
    }
  }
}
