import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/network/websocket_service.dart';
import '../data/conversation_repository.dart';

final conversationRepositoryProvider = Provider(
  (ref) => ConversationRepository(),
);

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
