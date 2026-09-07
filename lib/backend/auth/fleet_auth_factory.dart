import '../../features/auth/services/auth_service.dart';
import 'fleet_auth_adapter.dart';
import 'local_auth_adapter.dart';
import 'supabase_auth_adapter.dart';
import 'supabase_auth_gateway.dart';

enum FleetAuthMode { local, supabase }

FleetAuthAdapter createFleetAuthAdapter({
  FleetAuthMode mode = FleetAuthMode.local,
  AuthService? localAuthService,
  SupabaseAuthGateway? supabaseGateway,
}) => switch (mode) {
  FleetAuthMode.local => LocalAuthAdapter(localAuthService ?? AuthService.instance),
  FleetAuthMode.supabase => SupabaseAuthAdapter(supabaseGateway ?? (throw ArgumentError('Supabase gateway is required.'))),
};
