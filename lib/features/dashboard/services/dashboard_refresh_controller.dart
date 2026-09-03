import 'dart:async';

import '../models/dashboard_summary.dart';

/// Coordinates non-disruptive refresh requests for a mounted Dashboard.
///
/// It owns no Dashboard data. The screen remains responsible for presenting
/// loading, error, and retained-content states.
class DashboardRefreshController {
  DashboardRefreshController({
    required this._loadSummary,
    required this._onData,
    required this._onInitialError,
    this.interval = const Duration(seconds: 60),
  });

  final Future<DashboardSummary> Function() _loadSummary;
  final void Function(DashboardSummary summary) _onData;
  final void Function(Object error) _onInitialError;
  final Duration interval;

  Timer? _timer;
  bool _refreshInFlight = false;
  bool _hasData = false;
  bool _active = true;
  bool _disposed = false;

  bool get isRefreshing => _refreshInFlight;

  Future<void> loadInitial() => _refresh();

  Future<void> refresh() => _refresh();

  void startPeriodicRefresh() {
    _timer ??= Timer.periodic(interval, (_) {
      if (_active) {
        unawaited(refresh());
      }
    });
  }

  void setActive(bool active) {
    _active = active;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refresh() async {
    if (_disposed || _refreshInFlight) {
      return;
    }

    _refreshInFlight = true;
    try {
      final summary = await _loadSummary();
      if (_disposed) {
        return;
      }
      _hasData = true;
      _onData(summary);
    } catch (error) {
      if (!_disposed && !_hasData) {
        _onInitialError(error);
      }
    } finally {
      _refreshInFlight = false;
    }
  }
}
