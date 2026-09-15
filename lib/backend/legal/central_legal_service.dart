import '../backend_client.dart';

class CentralLegalDocument {
  const CentralLegalDocument({
    required this.kind,
    required this.version,
    required this.title,
    required this.content,
    required this.requiresAcceptance,
  });
  final String kind;
  final String version;
  final String title;
  final String content;
  final bool requiresAcceptance;
  factory CentralLegalDocument.fromJson(Map<String, dynamic> json) =>
      CentralLegalDocument(
        kind: json['kind']?.toString() ?? '',
        version: json['version']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        requiresAcceptance: json['requires_acceptance'] == true,
      );
}

class CentralLegalService {
  Future<List<CentralLegalDocument>> listCurrentDocuments() async {
    final rows = await BackendClient.client.rpc(
      'fleet_list_current_legal_documents',
    );
    if (rows is! List) throw StateError('Legal document response was invalid.');
    return rows
        .whereType<Map>()
        .map((e) => CentralLegalDocument.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);
  }

  Future<List<String>> requiredAcceptances() async {
    final rows = await BackendClient.client.rpc(
      'fleet_required_legal_acceptances',
    );
    if (rows is! List) return const [];
    return rows.map((e) => e.toString()).toList(growable: false);
  }

  Future<void> accept({required String kind, required String version}) async {
    await BackendClient.client.rpc(
      'fleet_accept_legal_document',
      params: {'p_kind': kind, 'p_version': version},
    );
  }

  Future<String> createDataRequest({
    required String requestType,
    required String details,
  }) async {
    final value = await BackendClient.client.rpc(
      'fleet_create_data_request',
      params: {'p_request_type': requestType, 'p_details': details.trim()},
    );
    return value.toString();
  }

  Future<String> createOffboardingRequest({
    required bool requestExport,
    required String details,
  }) async {
    final value = await BackendClient.client.rpc(
      'fleet_create_offboarding_request',
      params: {'p_request_export': requestExport, 'p_details': details.trim()},
    );
    return value.toString();
  }
}
