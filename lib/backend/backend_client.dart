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
    );
    _initialized = true;
  }
}
