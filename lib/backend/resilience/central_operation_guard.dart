import 'central_connection_tracker.dart';
import 'central_failure_classifier.dart';

/// Wraps one Supabase-backed operation and records central availability without
/// changing the operation's normal success/error contract.
///
/// It intentionally rethrows the original error. Build 17.4.6.1 does not
/// introduce retries, queued writes or SQLite fallback.
class CentralOperationGuard {
  CentralOperationGuard({
    required this._tracker,
    this._classifier = const CentralFailureClassifier(),
  });

  final CentralConnectionTracker _tracker;
  final CentralFailureClassifier _classifier;

  Future<T> run<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      _tracker.recordSuccess();
      return result;
    } catch (error) {
      final kind = _classifier.classify(error);
      _tracker.recordFailure(kind, message: error.toString());
      rethrow;
    }
  }
}
