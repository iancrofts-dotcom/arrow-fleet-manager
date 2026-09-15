import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../backend/backend_client.dart';

abstract interface class InvitationPasswordGateway {
  Future<bool> hasInvitationSession();

  Future<void> updatePassword(String password);
}

class SupabaseInvitationPasswordGateway implements InvitationPasswordGateway {
  SupabaseInvitationPasswordGateway({
    SupabaseClient? client,
    this._callbackWait = const Duration(seconds: 5),
  }) : _client = client ?? BackendClient.client;

  final SupabaseClient _client;
  final Duration _callbackWait;

  bool _hasUsableSession(Session? session) =>
      session != null && !session.isExpired;

  @override
  Future<bool> hasInvitationSession() async {
    // The Web invitation callback is consumed asynchronously by Supabase.
    // On a fresh browser/tab currentSession can still be null for a short
    // period after startup even though the callback is valid. Do not reject
    // the invitation until we have given the auth client time to publish the
    // restored session.
    if (_hasUsableSession(_client.auth.currentSession)) {
      return true;
    }

    final completer = Completer<bool>();
    late final StreamSubscription<AuthState> subscription;
    Timer? timeout;

    void finish(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    subscription = _client.auth.onAuthStateChange.listen((state) {
      if (_hasUsableSession(state.session)) {
        finish(true);
      }
    }, onError: (_) => finish(false));

    // Re-check after subscribing so a session created between the first read
    // and listener registration cannot be missed.
    if (_hasUsableSession(_client.auth.currentSession)) {
      finish(true);
    }

    timeout = Timer(_callbackWait, () {
      finish(_hasUsableSession(_client.auth.currentSession));
    });

    try {
      return await completer.future;
    } finally {
      timeout.cancel();
      await subscription.cancel();
    }
  }

  @override
  Future<void> updatePassword(String password) async {
    await _client.auth.updateUser(UserAttributes(password: password));
    await _client.auth.signOut();
  }
}
