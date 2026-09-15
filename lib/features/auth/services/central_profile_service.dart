import '../../../backend/backend_client.dart';

class CentralProfileDetails {
  const CentralProfileDetails({
    required this.id,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.email,
  });

  final String id;
  final String username;
  final String fullName;
  final String phone;
  final String email;
}

class CentralProfileService {
  const CentralProfileService();

  Future<CentralProfileDetails> loadMyProfile() async {
    final user = BackendClient.client.auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to view your profile.');
    }
    final row = await BackendClient.client
        .from('profiles')
        .select('id, username, full_name, phone')
        .eq('id', user.id)
        .single();
    return CentralProfileDetails(
      id: row['id'] as String,
      username: (row['username'] as String?)?.trim() ?? '',
      fullName: (row['full_name'] as String?)?.trim() ?? '',
      phone: (row['phone'] as String?)?.trim() ?? '',
      email: user.email?.trim() ?? '',
    );
  }

  Future<void> updateMyProfile({
    required String fullName,
    required String phone,
  }) async {
    final name = fullName.trim();
    if (name.length < 2 || name.contains('@')) {
      throw ArgumentError('Enter your name, not an email address.');
    }
    await BackendClient.client.rpc(
      'fleet_update_my_profile',
      params: {'p_full_name': name, 'p_phone': phone.trim()},
    );
  }
}
