import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../config/app_config.dart';
import '../models/message_model.dart';
import '../utils/api_date_time.dart';

class PresenceModel {
  final String utilisateurId;
  final bool enLigne;
  final DateTime? derniereConnexion;

  const PresenceModel({
    required this.utilisateurId,
    required this.enLigne,
    this.derniereConnexion,
  });

  factory PresenceModel.fromJson(Map<String, dynamic> json) {
    return PresenceModel(
      utilisateurId: json['utilisateurId'].toString(),

      enLigne: json['enLigne'] == true,

      derniereConnexion: json['derniereConnexion'] != null
          ? ApiDateTime.parse(json['derniereConnexion'].toString())
          : null,
    );
  }
}

class MessageSuppressionModel {
  final String messageId;

  const MessageSuppressionModel({required this.messageId});

  factory MessageSuppressionModel.fromJson(Map<String, dynamic> json) {
    return MessageSuppressionModel(messageId: json['messageId'].toString());
  }
}

// WEBSOCKET SERVICE

class WebSocketService {
  WebSocketService._internal();

  static final WebSocketService instance = WebSocketService._internal();

  StompClient? _client;

  final _storage = const FlutterSecureStorage();

  // STREAM DES MESSAGES

  final _messageController = StreamController<MessageModel>.broadcast();

  Stream<MessageModel> get messageStream => _messageController.stream;

  final _messageSuppressionController =
      StreamController<MessageSuppressionModel>.broadcast();

  Stream<MessageSuppressionModel> get messageSuppressionStream =>
      _messageSuppressionController.stream;

  // STREAM "EN TRAIN D'ÉCRIRE"

  final _typingController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get typingStream => _typingController.stream;

  // STREAM DE PRÉSENCE

  final _presenceController = StreamController<PresenceModel>.broadcast();

  Stream<PresenceModel> get presenceStream => _presenceController.stream;

  // ÉTAT DE CONNEXION

  Completer<void> _connectedCompleter = Completer<void>();

  bool _isConnected = false;

  // CONNECTER LE WEBSOCKET

  Future<void> connect() async {
    // Mode mock

    if (AppConfig.useMockBackend) {
      return;
    }

    // Récupérer le JWT

    final token = await _storage.read(key: 'jwt_token');

    if (token == null) {
      return;
    }

    // Réinitialiser le Completer

    if (_connectedCompleter.isCompleted) {
      _connectedCompleter = Completer<void>();
    }

    _isConnected = false;

    // Créer le client STOMP

    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsBaseUrl,

        // JWT envoyé au backend
        stompConnectHeaders: {'Authorization': 'Bearer $token'},

        // Connexion réussie
        onConnect: _onConnect,

        // Une coupure réseau temporaire ne doit pas laisser l'utilisateur
        // bloqué en « hors ligne » jusqu'au prochain redémarrage de l'app.
        reconnectDelay: const Duration(seconds: 5),

        // Déconnexion
        onDisconnect: (frame) {
          _isConnected = false;

          if (_connectedCompleter.isCompleted) {
            _connectedCompleter = Completer<void>();
          }
        },

        // Erreur WebSocket
        onWebSocketError: (error) {
          developer.log('Erreur WebSocket: $error', name: 'WebSocketService');
        },

        // Erreur STOMP
        onStompError: (frame) {
          developer.log(
            'Erreur STOMP: ${frame.body}',
            name: 'WebSocketService',
          );
        },

        // Render peut être lent au démarrage
        connectionTimeout: const Duration(seconds: 150),

        // Heartbeat
        heartbeatOutgoing: const Duration(seconds: 10),

        heartbeatIncoming: const Duration(seconds: 10),
      ),
    );

    // Activer WebSocket

    _client!.activate();
  }

  // CONNEXION STOMP RÉUSSIE

  void _onConnect(StompFrame frame) {
    _isConnected = true;

    if (!_connectedCompleter.isCompleted) {
      _connectedCompleter.complete();
    }

    // NOTIFICATIONS / MESSAGES

    _client?.subscribe(
      destination: '/user/queue/notifications',

      callback: (frame) {
        if (frame.body == null) {
          return;
        }

        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;

          final message = MessageModel.fromJson(data);

          _messageController.add(message);
        } catch (e) {
          developer.log(
            'Erreur traitement message: $e',
            name: 'WebSocketService',
          );
        }
      },
    );

    // PRÉSENCE DES UTILISATEURS

    _client?.subscribe(
      destination: '/topic/presence',

      callback: (frame) {
        if (frame.body == null) {
          return;
        }

        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;

          final presence = PresenceModel.fromJson(data);

          _presenceController.add(presence);
        } catch (e) {
          developer.log(
            'Erreur traitement présence: $e',
            name: 'WebSocketService',
          );
        }
      },
    );
  }

  // ATTENDRE LA CONNEXION

  Future<void> _ensureConnected() async {
    if (_isConnected) {
      return;
    }

    try {
      await _connectedCompleter.future.timeout(const Duration(seconds: 150));
    } catch (_) {
      // Le timeout est volontairement silencieux.
      // L'appel suivant échouera proprement si nécessaire.
    }
  }

  // S'ABONNER À UNE CONVERSATION

  Future<void> subscribeToConversation(String conversationId) async {
    await _ensureConnected();

    _client?.subscribe(
      destination: '/topic/conversation.$conversationId',

      callback: (frame) {
        if (frame.body == null) {
          return;
        }

        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;

          final message = MessageModel.fromJson(data);

          _messageController.add(message);
        } catch (e) {
          developer.log(
            'Erreur message conversation: $e',
            name: 'WebSocketService',
          );
        }
      },
    );

    _client?.subscribe(
      destination: '/topic/conversation.$conversationId.typing',
      callback: (frame) {
        if (frame.body == null) return;

        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _typingController.add(data);
        } catch (e) {
          developer.log(
            'Erreur notification de frappe: $e',
            name: 'WebSocketService',
          );
        }
      },
    );

    _client?.subscribe(
      destination: '/topic/conversation.$conversationId.deleted',
      callback: (frame) {
        if (frame.body == null) return;

        try {
          final data = jsonDecode(frame.body!) as Map<String, dynamic>;
          _messageSuppressionController.add(
            MessageSuppressionModel.fromJson(data),
          );
        } catch (e) {
          developer.log(
            'Erreur suppression message: $e',
            name: 'WebSocketService',
          );
        }
      },
    );
  }

  // ENVOYER UN MESSAGE

  Future<void> envoyerMessage({
    required String conversationId,
    required String contenu,
    MessageType type = MessageType.texte,
    String? messageParentId,
  }) async {
    await _ensureConnected();

    _client?.send(
      destination: '/app/chat.send',

      body: jsonEncode({
        'conversationId': int.parse(conversationId),

        'contenu': contenu,

        'type': type.name.toUpperCase(),

        if (messageParentId != null)
          'messageParentId': int.parse(messageParentId),
      }),
    );
  }

  // NOTIFIER "EN TRAIN D'ÉCRIRE"

  Future<void> notifierEnTrainDecrire(String conversationId) async {
    await _ensureConnected();

    _client?.send(
      destination: '/app/chat.typing',

      body: jsonEncode({'conversationId': int.parse(conversationId)}),
    );
  }

  // DÉCONNECTER LE WEBSOCKET

  Future<void> disconnect() async {
    try {
      if (_client != null) {
        _client!.deactivate();
      }
    } catch (e) {
      developer.log(
        'Erreur déconnexion WebSocket: $e',
        name: 'WebSocketService',
      );
    }

    _client = null;
    _isConnected = false;

    if (_connectedCompleter.isCompleted) {
      _connectedCompleter = Completer<void>();
    }
  }
}
