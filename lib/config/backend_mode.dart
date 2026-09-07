import 'backend_config.dart';

enum BackendMode { local, supabase }

class BackendModeConfig {
  const BackendModeConfig._();

  static const _configuredValue = String.fromEnvironment(
    'FLEETIQ_BACKEND_MODE',
    defaultValue: 'local',
  );

  static BackendMode get current => parse(_configuredValue);

  static BackendMode parse(String value) => switch (value) {
    'local' => BackendMode.local,
    'supabase' => BackendMode.supabase,
    _ => throw StateError(
      'Invalid FLEETIQ_BACKEND_MODE. Expected local or supabase.',
    ),
  };

  static String? validate({
    required String mode,
    required String supabaseUrl,
    required String supabasePublishableKey,
  }) {
    final parsedMode = switch (mode) {
      'local' => BackendMode.local,
      'supabase' => BackendMode.supabase,
      _ => null,
    };
    if (parsedMode == null) {
      return 'Invalid FLEETIQ_BACKEND_MODE. Expected local or supabase.';
    }
    if (parsedMode == BackendMode.supabase) {
      return BackendConfig.validate(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
      );
    }
    return null;
  }

  static void requireConfigured() {
    final error = validate(
      mode: _configuredValue,
      supabaseUrl: BackendConfig.supabaseUrl,
      supabasePublishableKey: BackendConfig.supabasePublishableKey,
    );
    if (error != null) {
      throw StateError(error);
    }
  }
}
