import 'dart:js_interop';

import 'invitation_route.dart';

@JS()
extension type _BrowserHistory._(JSObject _) implements JSObject {
  external void replaceState(JSAny? state, String unused, String url);
}

@JS('window.history')
external _BrowserHistory get _browserHistory;

void sanitizeInvitationUrl() {
  _browserHistory.replaceState(
    null,
    '',
    InvitationRoute.sanitizedLocation(Uri.base),
  );
}
