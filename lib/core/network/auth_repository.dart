import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;
  final _storage = const FlutterSecureStorage();

  Future<void> login(String email, String motDePasse) async {
    final response = await _api.login(email, motDePasse);
    await _enregistrerToken(response.data);
  }

  Future<void> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String role,
  }) async {
    final response = await _api.inscrire(
      nom: nom,
      prenom: prenom,
      email: email,
      motDePasse: motDePasse,
      role: role,
    );
    await _enregistrerToken(response.data);
  }

  Future<void> _enregistrerToken(dynamic donnees) async {
    final token = donnees['token'] as String;
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(
      key: 'utilisateur_id',
      value: donnees['userId']?.toString(),
    );
  }

  Future<String?> idUtilisateurConnecte() =>
      _storage.read(key: 'utilisateur_id');

  Future<bool> estConnecte() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }

  Future<void> deconnexion() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'utilisateur_id');
  }
}
