import '../backend/auth/fleet_auth_factory.dart';
import '../backend/auth/supabase_sdk_auth_gateway.dart';
import '../backend/backend_client.dart';
import '../config/backend_mode.dart';
import '../features/auth/services/auth_service.dart';
import '../platform/platform_runtime.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    BackendModeConfig.requireConfigured();
    final mode = BackendModeConfig.current;
    if (mode == BackendMode.local && !PlatformRuntime.supportsLocalData) {
      throw UnsupportedError(
        'The local data backend is unavailable on this platform.',
      );
    }
    if (mode == BackendMode.supabase) {
      await BackendClient.initialize();
      AuthService.instance.configureBackend(
        mode: mode,
        remoteAuthAdapter: createFleetAuthAdapter(
          mode: mode,
          supabaseGateway: SupabaseSdkAuthGateway(),
        ),
      );
      return;
    }
    AuthService.instance.configureBackend(mode: mode);
  }
}
