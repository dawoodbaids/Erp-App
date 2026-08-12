import 'package:shared_preferences/shared_preferences.dart';

import '../../models/auth_session.dart';

/// Persists the JWT auth session locally so the user stays signed in between
/// app launches.
class TokenStorage {
  TokenStorage._();

  static const _tokenKey = 'auth_token';
  static const _expiresAtKey = 'auth_expires_at';
  static const _usernameKey = 'auth_username';
  static const _fullNameKey = 'auth_full_name';

  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _instance async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await _instance;
    await prefs.setString(_tokenKey, session.token);
    await prefs.setString(_expiresAtKey, session.expiresAt.toIso8601String());
    await prefs.setString(_usernameKey, session.username);
    await prefs.setString(_fullNameKey, session.fullName);
  }

  static Future<AuthSession?> readSession() async {
    final prefs = await _instance;
    final token = prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) return null;
    return AuthSession(
      token: token,
      expiresAt:
          DateTime.tryParse(prefs.getString(_expiresAtKey) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      username: prefs.getString(_usernameKey) ?? '',
      fullName: prefs.getString(_fullNameKey) ?? '',
    );
  }

  static Future<String?> readToken() async {
    final session = await readSession();
    if (session == null || session.isExpired) return null;
    return session.token;
  }

  static Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_tokenKey);
    await prefs.remove(_expiresAtKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_fullNameKey);
  }
}
