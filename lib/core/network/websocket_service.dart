import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config/app_config.dart';
import '../models/message_model.dart';

class WebSocketService {
  WebSocketService._internal();
  static final WebSocketService instance = WebSocketService._internal();

  StompClient? _client;
  final _storage = const FlutterSecureStorage();

  final _messageController = StreamController<MessageModel>.broadcast();
  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  Completer<void> _connectedCompleter = Completer<void>();
  bool _isConnected = false;

  Future<void> connect() async {
    if (AppConfig.useMockBackend) return;

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return;

    if (_connectedCompleter.isCompleted) {
      _connectedCompleter = Completer<void>();
    }
    _isConnected = false;

    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsBaseUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onDisconnect: (frame) {
          _isConnected = false;
          if (_connectedCompleter.isCompleted) {
            _connectedCompleter = Completer<void>();
          }
        },
        onWebSocketError: (error) => print('Erreur WebSocket: $error'),
        onStompError: (frame) => print('Erreur STOMP: ${frame.body}'),
        // Render (offre gratuite) : le reveil complet a pris jusqu'a 130s
        // dans nos tests (Docker + JVM + Spring Boot). On laisse une
        // marge large plutot que d'echouer sur un serveur juste lent.
        connectionTimeout: const Duration(seconds: 150),
        // IMPORTANT : sans heartbeat, le serveur Spring ferme les sessions
        // WebSocket inactives au bout de ~100s ("No messages received
        // after 100500 ms. Closing..." vu dans les logs Render). Ces deux
        // lignes envoient un ping toutes les 10s pour garder la connexion
        // vivante meme quand personne n'ecrit de message.
        heartbeatOutgoing: const Duration(seconds: 10),
        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    if (!_connectedCompleter.isCompleted) {
      _connectedCompleter.complete();
    }
    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _messageController.add(MessageModel.fromJson(data));
        }
      },
    );
  }

  Future<void> _ensureConnected() async {
    if (_isConnected) return;
    try {
      await _connectedCompleter.future.timeout(const Duration(seconds: 150));
    } catch (_) {
      // Timeout : on continue quand meme, l'appel echouera proprement.
    }
  }

  Future<void> subscribeToConversation(String conversationId) async {
    await _ensureConnected();
    _client?.subscribe(
      destination: '/topic/conversation.$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _messageController.add(MessageModel.fromJson(data));
        }
      },
    );
  }

  Future<void> envoyerMessage({
    required String conversationId,
    required String contenu,
    MessageType type = MessageType.texte,
  }) async {
    await _ensureConnected();
    _client?.send(
      destination: '/app/chat.send',
      body: jsonEncode({
        'conversationId': int.parse(conversationId),
        'contenu': contenu,
        'type': type.name.toUpperCase(),
      }),
    );
  }

  Future<void> notifierEnTrainDecrire(String conversationId) async {
    await _ensureConnected();
    _client?.send(
      destination: '/app/chat.typing',
      body: jsonEncode({'conversationId': int.parse(conversationId)}),
    );
  }
}
