import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/auth_session.dart';

class AuthService {
  Future<AuthSession> login(String username, String password) async {
    final data = await ApiClient.postData(
      ApiConfig.loginPath,
      data: {'username': username, 'password': password},
    );
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }
}
