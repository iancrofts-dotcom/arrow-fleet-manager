import 'package:shared_preferences/shared_preferences.dart';

import '../backend_client.dart';
import '../resilience/central_failure_classifier.dart';
import '../resilience/central_failure_kind.dart';
import 'central_organisation.dart';
import 'central_organisation_member.dart';
import 'central_organisation_settings.dart';
import '../resilience/central_resilience_runtime.dart';
import '../resilience/supabase_resilience_scope_provider.dart';

/// Resolves FleetIQ's active organisation from a server-authoritative
/// membership path. The only offline fallback is the last organisation ID
/// previously confirmed by the server for the currently authenticated user.
class CentralOrganisationService {
  CentralOrganisationService({
    this._classifier = const CentralFailureClassifier(),
  });

  static final CentralOrganisationService instance =
      CentralOrganisationService();

  final CentralFailureClassifier _classifier;

  Future<String> currentOrganisationId() async {
    final user = BackendClient.client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated FleetIQ user is required.');
    }

    try {
      final value = await BackendClient.client.rpc(
        'fleet_current_organisation_id',
      );
      final organisationId = value?.toString().trim() ?? '';
      if (organisationId.isEmpty) {
        throw StateError(
          'No active FleetIQ organisation membership is available.',
        );
      }
      await _saveConfirmedOrganisation(user.id, organisationId);
      return organisationId;
    } catch (error) {
      final kind = _classifier.classify(error);
      if (kind != CentralFailureKind.connectivity &&
          kind != CentralFailureKind.timeout) {
        rethrow;
      }
      final cached = await _readConfirmedOrganisation(user.id);
      if (cached == null || cached.isEmpty) rethrow;
      return cached;
    }
  }

  Future<List<CentralOrganisation>> listMyOrganisations() async {
    final rows = await BackendClient.client.rpc('fleet_list_my_organisations');
    if (rows is! List) {
      throw StateError('Organisation membership response was invalid.');
    }
    return rows
        .whereType<Map>()
        .map(
          (row) => CentralOrganisation.fromJson(Map<String, dynamic>.from(row)),
        )
        .toList(growable: false);
  }

  Future<CentralOrganisation> createOrganisation({
    required String name,
    required String slug,
  }) async {
    final row = await BackendClient.client.rpc(
      'fleet_create_organisation',
      params: {'p_name': name.trim(), 'p_slug': slug.trim().toLowerCase()},
    );
    if (row is! Map) {
      throw StateError('Company creation response was invalid.');
    }
    return CentralOrganisation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<CentralOrganisation> updateCurrentOrganisation({
    required String name,
  }) async {
    final row = await BackendClient.client.rpc(
      'fleet_update_current_organisation',
      params: {'p_name': name.trim()},
    );
    if (row is! Map) {
      throw StateError('Company update response was invalid.');
    }
    return CentralOrganisation.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<CentralOrganisationMember>>
  listCurrentOrganisationMembers() async {
    final rows = await BackendClient.client.rpc(
      'fleet_list_current_organisation_members',
    );
    if (rows is! List) {
      throw StateError('Company member response was invalid.');
    }
    return rows
        .whereType<Map>()
        .map(
          (row) => CentralOrganisationMember.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList(growable: false);
  }

  Future<CentralOrganisationSettings> getCurrentOrganisationSettings() async {
    final row = await BackendClient.client.rpc(
      'fleet_get_current_organisation_settings',
    );
    if (row is! Map) {
      throw StateError('Company settings response was invalid.');
    }
    return CentralOrganisationSettings.fromJson(Map<String, dynamic>.from(row));
  }

  Future<CentralOrganisationSettings> updateCurrentOrganisationSettings({
    required String name,
    required String legalName,
    required String contactEmail,
    required String phone,
    required String addressLine1,
    required String addressLine2,
    required String townCity,
    required String postcode,
    required String companyNumber,
    required String reportFooter,
  }) async {
    final row = await BackendClient.client.rpc(
      'fleet_update_current_organisation_settings',
      params: {
        'p_name': name.trim(),
        'p_legal_name': legalName.trim(),
        'p_contact_email': contactEmail.trim(),
        'p_phone': phone.trim(),
        'p_address_line1': addressLine1.trim(),
        'p_address_line2': addressLine2.trim(),
        'p_town_city': townCity.trim(),
        'p_postcode': postcode.trim(),
        'p_company_number': companyNumber.trim(),
        'p_report_footer': reportFooter.trim(),
      },
    );
    if (row is! Map) {
      throw StateError('Company settings response was invalid.');
    }
    return CentralOrganisationSettings.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> transferCurrentOrganisationOwnership(
    String newOwnerUserId,
  ) async {
    final normalized = newOwnerUserId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        newOwnerUserId,
        'newOwnerUserId',
        'Must not be empty.',
      );
    }
    await BackendClient.client.rpc(
      'fleet_transfer_current_organisation_ownership',
      params: {'p_new_owner_user_id': normalized},
    );
  }

  Future<void> ensureSafeToSwitchOrganisation() async {
    final scope = await SupabaseResilienceScopeProvider().currentScope();
    final pending = await CentralResilienceRuntime.instance.pendingWrites(
      scope,
    );
    if (pending > 0) {
      throw StateError(
        'Sync pending offline changes before switching company.',
      );
    }
  }

  Future<void> setActiveOrganisation(String organisationId) async {
    final normalized = organisationId.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        organisationId,
        'organisationId',
        'Must not be empty.',
      );
    }
    final user = BackendClient.client.auth.currentUser;
    if (user == null) {
      throw StateError('An authenticated FleetIQ user is required.');
    }
    await BackendClient.client.rpc(
      'fleet_set_active_organisation',
      params: {'p_organisation_id': normalized},
    );
    await _saveConfirmedOrganisation(user.id, normalized);
  }

  Future<void> clearLocalSelection() async {
    final user = BackendClient.client.auth.currentUser;
    if (user == null) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey(user.id));
  }

  Future<void> _saveConfirmedOrganisation(
    String userId,
    String organisationId,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey(userId), organisationId);
  }

  Future<String?> _readConfirmedOrganisation(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_storageKey(userId))?.trim();
  }

  String _storageKey(String userId) =>
      'fleetiq.central.confirmed_organisation.v1.$userId';
}
