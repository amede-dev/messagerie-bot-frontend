import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        // Render (offre gratuite) met le serveur en veille apres 15 min
        // d'inactivite : le reveil complet (Docker + JVM + Spring Boot)
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) => handler.next(error),
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  Dio get dio => _dio;

  // ---- Authentification ----
  Future<Response> login(String email, String motDePasse) => _dio.post(
    '/api/auth/login',
    data: {'email': email, 'motDePasse': motDePasse},
  );

  Future<Response> inscrire({
    required String nom,
    required String prenom,
    required String email,
    required String motDePasse,
    required String role,
    required String parcours,
    required String niveau,
  }) => _dio.post(
    '/api/auth/register',
    data: {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'motDePasse': motDePasse,
      'role': role,
      'parcours': parcours,
      'niveau': niveau,
    },
  );

  // ---- Conversations ----
  Future<Response> getConversations() => _dio.get('/api/conversations');

  Future<Response> getMessages(String conversationId, {int page = 0}) =>
      _dio.get(
        '/api/conversations/$conversationId/messages',
        queryParameters: {'page': page},
      );

  Future<Response> creerConversation(Map<String, dynamic> payload) =>
      _dio.post('/api/conversations', data: payload);

  // ---- Messages ----
  Future<Response> envoyerMessageRest(Map<String, dynamic> payload) =>
      _dio.post(
        '/api/conversations/${payload['conversationId']}/messages',
        data: payload,
      );

  Future<Response> marquerStatut(String messageId, String statut) =>
      _dio.put('/api/messages/$messageId/status', data: {'statut': statut});

  Future<Response> modifierMessage(String messageId, String contenu) =>
      _dio.put('/api/messages/$messageId', data: {'contenu': contenu});

  Future<Response> signalerMessage(String messageId, String motif) =>
      _dio.post('/api/messages/$messageId/report', data: {'motif': motif});

  Future<Response> supprimerMessage(String messageId) =>
      _dio.delete('/api/messages/$messageId');

  // ---- Bot ----
  Future<Response> envoyerMessageBot(String texte) =>
      _dio.post('/api/bot/message', data: {'texte': texte});

  // ---- Moderation ----
  Future<Response> bloquerUtilisateur(String userId) =>
      _dio.post('/api/users/$userId/block');

  // ---- Utilisateurs (pour choisir des participants) ----
  Future<Response> getUsers() => _dio.get('/api/users');

  Future<Response> getMonProfil() => _dio.get('/api/users/me/profile');

  Future<Response> getNotifications() => _dio.get('/api/notifications');

  Future<Response> supprimerNotification(String id) =>
      _dio.delete('/api/notifications/$id');

  Future<Response> supprimerToutesLesNotifications() =>
      _dio.delete('/api/notifications');

  Future<Response> quitterConversation(String conversationId) =>
      _dio.delete('/api/conversations/$conversationId');
}
