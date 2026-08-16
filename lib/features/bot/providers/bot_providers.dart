import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/message_model.dart';
import '../../../core/network/api_client.dart';

// Un message affiché dans le chat bot : soit celui de l'utilisateur,
// soit la réponse du bot avec ses suggestions éventuelles.
class BotChatEntry {
  final MessageModel message;
  final List<String> suggestions;

  const BotChatEntry({required this.message, this.suggestions = const []});
}

final botChatProvider = NotifierProvider<BotChatNotifier, List<BotChatEntry>>(
  BotChatNotifier.new,
);

class BotChatNotifier extends Notifier<List<BotChatEntry>> {
  @override
  List<BotChatEntry> build() {
    return [
      BotChatEntry(
        message: MessageModel(
          id: 'welcome',
          conversationId: 'bot',
          expediteurId: 'bot',
          expediteurNom: 'Assistant Uni',
          contenu: 'Bonjour, comment puis-je t\'aider aujourd\'hui ?',
          type: MessageType.texte,
          statut: MessageStatut.lu,
          dateEnvoi: DateTime.now(),
        ),
        suggestions: const ['Mon emploi du temps', 'Contacter un humain'],
      ),
    ];
  }

  Future<void> envoyer(String texte) async {
    _ajouterMessageUtilisateur(texte);

    try {
      final response = await ApiClient.instance.envoyerMessageBot(texte);
      final data = response.data as Map<String, dynamic>;
      state = [
        ...state,
        BotChatEntry(
          message: MessageModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            conversationId: 'bot',
            expediteurId: 'bot',
            expediteurNom: 'Assistant Uni',
            contenu: data['texte'] as String? ?? '',
            type: MessageType.texte,
            statut: MessageStatut.lu,
            dateEnvoi: DateTime.now(),
          ),
          suggestions:
              (data['suggestions'] as List?)?.cast<String>() ?? const [],
        ),
      ];
    } catch (_) {
      state = [
        ...state,
        BotChatEntry(
          message: MessageModel(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            conversationId: 'bot',
            expediteurId: 'bot',
            expediteurNom: 'Assistant Uni',
            contenu:
                'Désolé, je rencontre un problème. Réessaie dans un instant.',
            type: MessageType.texte,
            statut: MessageStatut.lu,
            dateEnvoi: DateTime.now(),
          ),
        ),
      ];
    }
  }

  void _ajouterMessageUtilisateur(String texte) {
    state = [
      ...state,
      BotChatEntry(
        message: MessageModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          conversationId: 'bot',
          expediteurId: 'me',
          expediteurNom: 'Moi',
          contenu: texte,
          type: MessageType.texte,
          statut: MessageStatut.envoye,
          dateEnvoi: DateTime.now(),
        ),
      ),
    ];
  }
}
