import '../../../core/config/app_config.dart';
import '../../../core/models/app_user_model.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/network/api_client.dart';

class ConversationRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<ConversationModel>> fetchConversations() async {
    if (AppConfig.useMockBackend) return _mockConversations();

    final response = await _api.getConversations();
    final data = response.data as List;
    return data
        .map((json) => ConversationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<MessageModel>> fetchMessages(
    String conversationId, {
    int page = 0,
  }) async {
    if (AppConfig.useMockBackend) return _mockMessages(conversationId);

    final response = await _api.getMessages(conversationId, page: page);
    final data = response.data as Map<String, dynamic>;
    final content = data['content'] as List;
    final messages = content
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();

    messages.sort((a, b) => a.dateEnvoi.compareTo(b.dateEnvoi));
    return messages;
  }

  // Annuaire des utilisateurs, issu de la table `app_user`

  Future<List<AppUserModel>> fetchUsers() async {
    if (AppConfig.useMockBackend) {
      return const [AppUserModel(id: '2', nom: 'Rakoto', prenom: 'Hery')];
    }
    final response = await _api.getUsers();
    final data = response.data as List;
    return data
        .map((json) => AppUserModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Démarre une conversation privée avec l'utilisat dont l'identifiant est [autreUtilisateurId].
  Future<ConversationModel> creerConversationPrivee(
    String autreUtilisateurId,
  ) async {
    if (AppConfig.useMockBackend) {
      return ConversationModel(
        id: 'mock-priv-${DateTime.now().millisecondsSinceEpoch}',
        type: ConversationType.privee,
        nom: 'Nouvelle discussion',
      );
    }

    final response = await _api.creerConversation({
      'type': 'PRIVEE',
      'participantIds': [autreUtilisateurId],
    });
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> marquerMessageLu(String messageId) async {
    if (AppConfig.useMockBackend) return;
    await _api.marquerStatut(messageId, 'LU');
  }

  Future<MessageModel> modifierMessage(String messageId, String contenu) async {
    if (AppConfig.useMockBackend) {
      throw UnsupportedError('Modification indisponible en mode mock');
    }
    final response = await _api.modifierMessage(messageId, contenu);
    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MessageModel> envoyerMessage(
    String conversationId,
    String contenu, {
    MessageType type = MessageType.texte,
  }) async {
    if (AppConfig.useMockBackend) {
      throw UnsupportedError('Envoi indisponible en mode mock');
    }

    final response = await _api.envoyerMessageRest({
      'conversationId': conversationId,
      'contenu': contenu,
      'type': type.name.toUpperCase(),
    });

    return MessageModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> signalerMessage(String messageId, String motif) async {
    if (AppConfig.useMockBackend) return;
    await _api.signalerMessage(messageId, motif);
  }

  Future<void> supprimerMessagePourTous(String messageId) async {
    if (AppConfig.useMockBackend) return;
    await _api.supprimerMessage(messageId);
  }

  Future<void> bloquerUtilisateur(String userId) async {
    if (AppConfig.useMockBackend) return;
    await _api.bloquerUtilisateur(userId);
  }

  // Retirer une conversation privée.
  Future<void> quitterConversation(String conversationId) async {
    if (AppConfig.useMockBackend) return;
    await _api.quitterConversation(conversationId);
  }

  List<ConversationModel> _mockConversations() {
    final maintenant = DateTime.now();
    return [
      ConversationModel(
        id: 'conv-1',
        type: ConversationType.privee,
        nom: 'Hery Rakoto',
        avatarInitiales: 'HR',
        estEnLigne: true,
        dernierMessage: MessageModel(
          id: 'm2',
          conversationId: 'conv-2',
          expediteurId: 'me',
          expediteurNom: 'Moi',
          contenu: "D'accord, on se retrouve à la bib",
          type: MessageType.texte,
          statut: MessageStatut.lu,
          dateEnvoi: maintenant.subtract(const Duration(hours: 20)),
        ),
      ),
    ];
  }

  List<MessageModel> _mockMessages(String conversationId) {
    final maintenant = DateTime.now();
    return [
      MessageModel(
        id: 'h1',
        conversationId: conversationId,
        expediteurId: 'u2',
        expediteurNom: 'Rina',
        contenu: 'Salut, ça va ?',
        type: MessageType.texte,
        statut: MessageStatut.lu,
        dateEnvoi: maintenant.subtract(const Duration(minutes: 40)),
      ),
      MessageModel(
        id: 'h2',
        conversationId: conversationId,
        expediteurId: 'me',
        expediteurNom: 'Moi',
        contenu: 'Ça va bien et toi ?',
        type: MessageType.texte,
        statut: MessageStatut.lu,
        dateEnvoi: maintenant.subtract(const Duration(minutes: 35)),
      ),
      MessageModel(
        id: 'h3',
        conversationId: conversationId,
        expediteurId: 'u2',
        expediteurNom: 'Rina',
        contenu: 'Le TP est reporté à demain',
        type: MessageType.texte,
        statut: MessageStatut.recu,
        dateEnvoi: maintenant.subtract(const Duration(minutes: 20)),
      ),
    ];
  }
}
