import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/conversation_model.dart';
import '../../../core/models/app_user_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/network/websocket_service.dart';
import '../data/conversation_repository.dart';

final conversationRepositoryProvider = Provider(
  (ref) => ConversationRepository(),
);

/// Annuaire affiché en haut de l'accueil, à la manière des contacts actifs
/// dans les applications de messagerie. Les données viennent de `/api/users`.
final contactsUniversitairesProvider = FutureProvider<List<AppUserModel>>((
  ref,
) async {
  final contacts = await ref.read(conversationRepositoryProvider).fetchUsers();
  contacts.sort(
    (a, b) => a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase()),
  );
  return contacts;
});

/// Participants connus par le client pour les groupes créés pendant la session.
/// Une API GET dédiée est nécessaire pour conserver cette liste après relance.
final participantsGroupesProvider =
    StateProvider<Map<String, List<AppUserModel>>>((ref) => {});

/// Liste des conversations affichée sur l'écran d'accueil de la messagerie.
final conversationListProvider =
    AsyncNotifierProvider<ConversationListNotifier, List<ConversationModel>>(
      ConversationListNotifier.new,
    );

class ConversationListNotifier extends AsyncNotifier<List<ConversationModel>> {
  @override
  Future<List<ConversationModel>> build() async {
    final repo = ref.read(conversationRepositoryProvider);
    return repo.fetchConversations();
  }

  Future<void> rafraichir() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(conversationRepositoryProvider).fetchConversations(),
    );
  }

  void retirerConversation(String conversationId) {
    final actuel = state.valueOrNull;
    if (actuel == null) return;
    state = AsyncData(actuel.where((c) => c.id != conversationId).toList());
  }

  /// Retire immédiatement l'indicateur de non-lus lorsque la discussion est
  /// ouverte. Le serveur reste la source de vérité après le rafraîchissement.
  void marquerConversationLue(String conversationId) {
    final actuel = state.valueOrNull;
    if (actuel == null) return;
    state = AsyncData(
      actuel
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(nombreNonLus: 0)
                : conversation,
          )
          .toList(),
    );
  }

  void renommerConversation(String conversationId, String nom) {
    final actuel = state.valueOrNull;
    if (actuel == null) return;
    state = AsyncData(
      actuel
          .map(
            (conversation) => conversation.id == conversationId
                ? conversation.copyWith(nom: nom)
                : conversation,
          )
          .toList(),
    );
  }
}

// Historique + flux temps réel des messages d'une conversation ouverte.
final chatMessagesProvider =
    AsyncNotifierProvider.family<
      ChatMessagesNotifier,
      List<MessageModel>,
      String
    >(ChatMessagesNotifier.new);

class ChatMessagesNotifier
    extends FamilyAsyncNotifier<List<MessageModel>, String> {
  @override
  Future<List<MessageModel>> build(String conversationId) async {
    WebSocketService.instance.subscribeToConversation(conversationId);
    WebSocketService.instance.messageStream.listen((message) {
      if (message.conversationId == conversationId) {
        _ajouterMessage(message);
      }
    });

    final repo = ref.read(conversationRepositoryProvider);
    final historique = await repo.fetchMessages(conversationId);
    return historique;
  }

  void _ajouterMessage(MessageModel message) {
    final actuel = state.valueOrNull ?? [];
    state = AsyncData([...actuel, message]);
  }

  void envoyer(String texte) {
    WebSocketService.instance.envoyerMessage(
      conversationId: arg,
      contenu: texte,
      type: MessageType.texte,
    );
  }

  /// Les messages au statut « reçu » deviennent lus dès que la conversation
  /// est affichée. Les messages envoyés par l'utilisateur ne sont pas touchés.
  Future<void> marquerMessagesRecusCommeLus() async {
    final messagesRecus = (state.valueOrNull ?? const <MessageModel>[])
        .where((message) => message.statut == MessageStatut.recu)
        .toList();
    if (messagesRecus.isEmpty) return;

    final repo = ref.read(conversationRepositoryProvider);
    await Future.wait(
      messagesRecus.map((message) => repo.marquerMessageLu(message.id)),
    );

    final idsLus = messagesRecus.map((message) => message.id).toSet();
    final actuel = state.valueOrNull ?? const <MessageModel>[];
    state = AsyncData(
      actuel
          .map(
            (message) => idsLus.contains(message.id)
                ? message.copyWith(statut: MessageStatut.lu)
                : message,
          )
          .toList(),
    );
  }

  // Envoie une pièce jointe (image ou document) choisie via le bottom sheet.
  void envoyerPieceJointe(File fichier, {required bool estImage}) {
    WebSocketService.instance.envoyerMessage(
      conversationId: arg,
      contenu: fichier.path,
      type: estImage ? MessageType.image : MessageType.document,
    );
  }

  void notifierFrappe() {
    WebSocketService.instance.notifierEnTrainDecrire(arg);
  }
}
