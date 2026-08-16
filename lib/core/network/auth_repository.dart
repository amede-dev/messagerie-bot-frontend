import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;
  final _storage = const FlutterSecureStorage();

  Future<void> login(String email, String motDePasse) async {
    final response = await _api.login(email, motDePasse);
    final token = response.data['token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<bool> estConnecte() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<void> deconnexion() async {
    await _storage.delete(key: 'jwt_token');
  }
}