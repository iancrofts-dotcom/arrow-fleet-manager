import 'package:flutter/foundation.dart';

class InvitationRoute {
  const InvitationRoute._();

  static const path = '/set-password';
  static const queryParameter = 'route';
  static const queryValue = 'set-password';

  static String initialRoute({Uri? uri, bool? isWeb}) {
    final currentUri = uri ?? Uri.base;
    final runningOnWeb = isWeb ?? kIsWeb;
    final isInvitationRoute =
        currentUri.path == path ||
        currentUri.queryParameters[queryParameter] == queryValue;
    return runningOnWeb && isInvitationRoute ? path : '/';
  }

  static String sanitizedLocation(Uri uri) {
    if (uri.queryParameters[queryParameter] == queryValue) {
      return Uri(
        path: uri.path.isEmpty ? '/' : uri.path,
        queryParameters: const {queryParameter: queryValue},
      ).toString();
    }
    return path;
  }
}
