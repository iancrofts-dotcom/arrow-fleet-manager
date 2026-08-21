import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  SessionService({Future<SharedPreferences> Function()? preferencesProvider})
    : _preferencesProvider =
          preferencesProvider ?? SharedPreferences.getInstance;

  static final SessionService instance = SessionService();

  static const _userIdKey = 'current_user_id';

  final Future<SharedPreferences> Function() _preferencesProvider;

  Future<void> saveUserId(String userId) async {
    final prefs = await _preferencesProvider();
    await prefs.setString(_userIdKey, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _preferencesProvider();
    return prefs.getString(_userIdKey);
  }

  Future<void> clearSession() async {
    final prefs = await _preferencesProvider();
    await prefs.remove(_userIdKey);
  }
}
