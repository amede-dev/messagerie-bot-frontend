import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

import '../network/websocket_service.dart';

class AuthRepository {
  final ApiClient _api = ApiClient.instance;

  final _storage = const FlutterSecureStorage();

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  Future<void> login(String email, String motDePasse) async {
    final response = await _api.login(email, motDePasse);

    await _enregistrerToken(response.data);
  }

  // ==========================================================================
  // INSCRIPTION
  // ==========================================================================

  Future<void> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String role,
    required String parcours,
    required String niveau,
  }) async {
    final response = await _api.inscrire(
      nom: nom,
      prenom: prenom,
      email: email,
      motDePasse: motDePasse,
      role: role,
      parcours: parcours,
      niveau: niveau,
    );

    await _enregistrerToken(response.data);
  }

  // ==========================================================================
  // ENREGISTRER LE TOKEN
  // ==========================================================================

  Future<void> _enregistrerToken(dynamic donnees) async {
    final token = donnees['token'] as String;

    await _storage.write(key: 'jwt_token', value: token);

    await _storage.write(
      key: 'utilisateur_id',
      value: donnees['userId']?.toString(),
    );
  }

  // ==========================================================================
  // ID UTILISATEUR CONNECTÉ
  // ==========================================================================

  Future<String?> idUtilisateurConnecte() {
    return _storage.read(key: 'utilisateur_id');
  }

  // ==========================================================================
  // VÉRIFIER LA CONNEXION
  // ==========================================================================

  Future<bool> estConnecte() async {
    final token = await _storage.read(key: 'jwt_token');

    return token != null;
  }

  // ==========================================================================
  // DÉCONNEXION
  // ==========================================================================

  Future<void> deconnexion() async {
    // ------------------------------------------------------------------------
    // IMPORTANT :
    //
    // On ferme d'abord le WebSocket.
    //
    // Le backend reçoit alors SessionDisconnectEvent
    // et peut enregistrer :
    //
    // enLigne = false
    // derniereConnexion = maintenant
    //
    // ------------------------------------------------------------------------

    await WebSocketService.instance.disconnect();

    // ------------------------------------------------------------------------
    // Ensuite seulement supprimer le JWT.
    // ------------------------------------------------------------------------

    await _storage.delete(key: 'jwt_token');

    await _storage.delete(key: 'utilisateur_id');
  }
}
