import '../../features/auth/services/auth_service.dart';
import '../../config/backend_mode.dart';
import 'fleet_auth_adapter.dart';
import 'local_auth_adapter.dart';
import 'supabase_auth_adapter.dart';
import 'supabase_auth_gateway.dart';

FleetAuthAdapter createFleetAuthAdapter({
  BackendMode mode = BackendMode.local,
  AuthService? localAuthService,
  SupabaseAuthGateway? supabaseGateway,
}) => switch (mode) {
  BackendMode.local => LocalAuthAdapter(
    localAuthService ?? AuthService.instance,
  ),
  BackendMode.supabase => SupabaseAuthAdapter(
    supabaseGateway ?? (throw ArgumentError('Supabase gateway is required.')),
  ),
};
