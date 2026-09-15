import 'central_failure_kind.dart';

/// Conservative classifier for central-operation failures.
///
/// Only errors that clearly describe network loss or a timeout are treated as
/// offline-capable failures. Authentication, authorization, backend/server and
/// unknown failures deliberately remain non-offline so FleetIQ never silently
/// redirects a central workflow to SQLite because of an unrelated error.
class CentralFailureClassifier {
  const CentralFailureClassifier();

  CentralFailureKind classify(Object error) {
    final text = error.toString().toLowerCase();

    if (_containsAny(text, const <String>['timeout', 'timed out'])) {
      return CentralFailureKind.timeout;
    }

    if (_containsAny(text, const <String>[
      'socketexception',
      'failed host lookup',
      'network is unreachable',
      'connection refused',
      'connection reset',
      'network request failed',
      'xmlhttprequest error',
      'failed to fetch',
    ])) {
      return CentralFailureKind.connectivity;
    }

    if (_containsAny(text, const <String>[
      'unauthorized',
      'invalid jwt',
      'jwt expired',
      'token has expired',
      'statuscode: 401',
      'status code: 401',
      'status: 401',
    ])) {
      return CentralFailureKind.authentication;
    }

    if (_containsAny(text, const <String>[
      'forbidden',
      'permission denied',
      'row-level security',
      'row level security',
      'statuscode: 403',
      'status code: 403',
      'status: 403',
    ])) {
      return CentralFailureKind.authorization;
    }

    if (_containsAny(text, const <String>[
      'internal server error',
      'bad gateway',
      'service unavailable',
      'gateway timeout',
      'statuscode: 500',
      'statuscode: 502',
      'statuscode: 503',
      'statuscode: 504',
      'status code: 500',
      'status code: 502',
      'status code: 503',
      'status code: 504',
      'status: 500',
      'status: 502',
      'status: 503',
      'status: 504',
    ])) {
      return CentralFailureKind.server;
    }

    return CentralFailureKind.unknown;
  }

  bool _containsAny(String text, List<String> values) {
    for (final value in values) {
      if (text.contains(value)) {
        return true;
      }
    }
    return false;
  }
}
