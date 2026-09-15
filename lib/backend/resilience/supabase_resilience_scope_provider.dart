import '../backend_client.dart';
import '../organisation/central_organisation_service.dart';
import 'central_resilience_scope.dart';
import 'central_resilience_scope_provider.dart';

class SupabaseResilienceScopeProvider
    implements CentralResilienceScopeProvider {
  SupabaseResilienceScopeProvider({CentralOrganisationService? organisations})
    : _organisations = organisations ?? CentralOrganisationService.instance;

  final CentralOrganisationService _organisations;

  @override
  Future<CentralResilienceScope> currentScope() async {
    final user = BackendClient.client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated FleetIQ user is required.');
    }
    return CentralResilienceScope(
      tenantId: await _organisations.currentOrganisationId(),
      userId: user.id,
    );
  }
}
