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

  Future<void> connect() async {
    if (AppConfig.useMockBackend) return;

    final token = await _storage.read(key: 'jwt_token');
    if (token == null) return; // pas connecte -> pas de WebSocket

    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsBaseUrl,
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        onConnect: _onConnect,
        onWebSocketError: (error) => print('Erreur WebSocket: $error'),
        onStompError: (frame) => print('Erreur STOMP: ${frame.body}'),
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
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

  void subscribeToConversation(String conversationId) {
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

  // Parametres nommes pour correspondre a conversation_providers.dart
  // (ChatMessagesNotifier.envoyer / envoyerPieceJointe).
  void envoyerMessage({
    required String conversationId,
    required String contenu,
    MessageType type = MessageType.texte,
  }) {
    _client?.send(
      destination: '/app/chat.send',
      body: jsonEncode({
        'conversationId': int.parse(conversationId),
        'contenu': contenu,
        'type': type.name.toUpperCase(),
      }),
    );
  }

  void notifierEnTrainDecrire(String conversationId) {
    _client?.send(
      destination: '/app/chat.typing',
      body: jsonEncode({'conversationId': int.parse(conversationId)}),
    );
  }
}
