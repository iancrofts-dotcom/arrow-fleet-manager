class CentralResilienceScope {
  const CentralResilienceScope({required this.tenantId, required this.userId});

  final String tenantId;
  final String userId;

  String get storageScope {
    final tenant = tenantId.trim();
    final user = userId.trim();
    if (tenant.isEmpty || user.isEmpty) {
      throw StateError(
        'Central resilience storage requires both tenantId and userId.',
      );
    }
    return '$tenant::$user';
  }
}
