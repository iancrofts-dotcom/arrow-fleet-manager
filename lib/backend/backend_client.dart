import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/backend_config.dart';

class BackendClient {
  BackendClient._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static SupabaseClient get client {
    if (!_initialized) {
      throw StateError('Backend client has not been initialized.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    BackendConfig.requireConfigured();
    await Supabase.initialize(
      url: BackendConfig.supabaseUrl,
      publishableKey: BackendConfig.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        // FleetIQ Web is a client-only application. Password-reset links are
        // commonly opened from a different tab/browser context than the one
        // that requested them, so a PKCE verifier may no longer be available.
        // Use the supported implicit callback flow on Web so recovery links
        // carry their session in the callback itself. Native builds retain
        // PKCE for deep-link authentication.
        authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
    _initialized = true;
  }
}
