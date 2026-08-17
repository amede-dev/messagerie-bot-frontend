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
    return content
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<ConversationModel> creerConversationGroupe({
    required String nom,
    required List<String> participantIds,
    String? groupeLieId,
  }) async {
    if (AppConfig.useMockBackend) {
      return ConversationModel(
        id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
        type: ConversationType.groupe,
        nom: nom,
        avatarInitiales: nom.isNotEmpty ? nom.substring(0, 1) : '?',
      );
    }

    final response = await _api.creerConversation({
      'type': 'GROUPE',
      'nom': nom,
      'participantIds': participantIds,
      if (groupeLieId != null) 'groupeLieId': groupeLieId,
    });
    return ConversationModel.fromJson(response.data as Map<String, dynamic>);
  }

  /// Annuaire des utilisateurs de l'université, issu de la table `app_user`
  /// (peuplée à partir de `Liste_consolidee_ENI_sans_doublons.xlsx`).
  /// Utilisé par l'écran "Nouvelle discussion" (contact_list_screen.dart)
  /// et par l'écran "Nouveau groupe" (new_conversation_screen.dart).
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

  /// Démarre (ou rouvre) une conversation privée (1 à 1) avec l'utilisateur
  /// dont l'identifiant est [autreUtilisateurId]. Côté backend, si une
  /// conversation privée existe déjà entre les deux utilisateurs, elle est
  /// retournée telle quelle : jamais de doublon, même en sélectionnant
  /// plusieurs fois le même contact dans l'annuaire.
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

  Future<void> signalerMessage(String messageId, String motif) async {
    if (AppConfig.useMockBackend) return;
    await _api.signalerMessage(messageId, motif);
  }

  Future<void> bloquerUtilisateur(String userId) async {
    if (AppConfig.useMockBackend) return;
    await _api.bloquerUtilisateur(userId);
  }

  /// Quitter un groupe (ou archiver une conversation privée).
  /// En mode mock : aucun appel réseau, le retrait visuel est géré côté
  /// provider (retirerConversation). Sinon : DELETE /api/conversations/{id}.
  Future<void> quitterConversation(String conversationId) async {
    if (AppConfig.useMockBackend) return;
    await _api.quitterConversation(conversationId);
  }

  // ---- Données factices (démo / dev sans backend) ----

  List<ConversationModel> _mockConversations() {
    final maintenant = DateTime.now();
    return [
      ConversationModel(
        id: 'conv-1',
        type: ConversationType.groupe,
        nom: 'Groupe L2 Info',
        avatarInitiales: 'L2I',
        nombreNonLus: 5,
        dernierMessage: MessageModel(
          id: 'm1',
          conversationId: 'conv-1',
          expediteurId: 'u2',
          expediteurNom: 'Rina',
          contenu: 'Le TP est reporté à demain',
          type: MessageType.texte,
          statut: MessageStatut.recu,
          dateEnvoi: maintenant.subtract(const Duration(minutes: 20)),
        ),
      ),
      ConversationModel(
        id: 'conv-2',
        type: ConversationType.privee,
        nom: 'Hery Rakoto',
        avatarInitiales: 'HR',
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
      ConversationModel(
        id: 'conv-3',
        type: ConversationType.groupe,
        nom: 'Club Informatique',
        avatarInitiales: 'CI',
        dernierMessage: MessageModel(
          id: 'm3',
          conversationId: 'conv-3',
          expediteurId: 'u3',
          expediteurNom: 'Mamy',
          contenu: 'Réunion vendredi 14h, salle B2',
          type: MessageType.texte,
          statut: MessageStatut.recu,
          dateEnvoi: maintenant.subtract(const Duration(days: 3)),
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
