/// Compile-time configuration for the future FleetIQ central backend.
///
/// The publishable client key is intended for client use; never provide a service-role key
/// or database credentials through these values.
class BackendConfig {
  const BackendConfig._();

  static const supabaseUrl = String.fromEnvironment('FLEETIQ_SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'FLEETIQ_SUPABASE_ANON_KEY',
  );

  static bool get isConfigured =>
      validate(url: supabaseUrl, publishableKey: supabasePublishableKey) ==
      null;

  static String? validate({
    required String url,
    required String publishableKey,
  }) {
    if (url.isEmpty) return 'Supabase URL is required.';
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      return 'Supabase URL must be an HTTP or HTTPS URL.';
    }
    if (publishableKey.isEmpty) return 'Supabase publishable key is required.';
    return null;
  }

  static void requireConfigured() {
    final error = validate(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
    if (error != null) {
      throw StateError(
        '$error Supply FLEETIQ_SUPABASE_URL and FLEETIQ_SUPABASE_ANON_KEY '
        'with --dart-define.',
      );
    }
  }
}
