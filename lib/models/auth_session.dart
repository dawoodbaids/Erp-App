import 'json_helpers.dart';
import 'user.dart';

/// The response returned by `POST /api/auth/login`.
class AuthSession {
  final String token;
  final DateTime expiresAt;
  final String username;
  final String fullName;

  const AuthSession({
    required this.token,
    required this.expiresAt,
    required this.username,
    required this.fullName,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    token: toStr(json['token']),
    expiresAt: toDate(json['expiresAt']),
    username: toStr(json['username']),
    fullName: toStr(json['fullName']),
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'expiresAt': expiresAt.toIso8601String(),
    'username': username,
    'fullName': fullName,
  };

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  User get toUser => User(id: '', username: username, displayName: fullName);
}
