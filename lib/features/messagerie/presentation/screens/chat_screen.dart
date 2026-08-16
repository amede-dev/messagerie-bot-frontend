import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/attachment_picker_sheet.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'conversation_settings_screen.dart';

// Écran de discussion générique (privé ou groupe)
class ChatScreen extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _scrollController = ScrollController();

  // TODO: remplacer par l'id réel de l'utilisateur connecté (auth provider global)
  static const _utilisateurCourantId = 'me';

  void _scrollEnBas() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// Ouvre le bottom sheet Caméra / Galerie / Document, puis envoie le
  /// fichier choisi dans la conversation courante.
  Future<void> _choisirEtEnvoyerPieceJointe() async {
    final selection = await afficherSelecteurPieceJointe(context);
    if (selection == null) return; // utilisateur a annulé

    ref
        .read(chatMessagesProvider(widget.conversation.id).notifier)
        .envoyerPieceJointe(selection.fichier, estImage: selection.estImage);
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversation.id),
    );
    final estGroupe = widget.conversation.type == ConversationType.groupe;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.nom),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConversationSettingsScreen(
                  conversation: widget.conversation,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur : $err')),
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _scrollEnBas(),
                );
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return MessageBubble(
                      message: message,
                      estUtilisateurCourant:
                          message.expediteurId == _utilisateurCourantId,
                      afficherNomExpediteur: estGroupe,
                    );
                  },
                );
              },
            ),
          ),
          if (widget.conversation.enTrainDecrire)
            TypingIndicator(nomUtilisateur: widget.conversation.nom),
          ChatInputBar(
            onSend: (texte) => ref
                .read(chatMessagesProvider(widget.conversation.id).notifier)
                .envoyer(texte),
            onTyping: () => ref
                .read(chatMessagesProvider(widget.conversation.id).notifier)
                .notifierFrappe(),
            onAttachmentTap: _choisirEtEnvoyerPieceJointe,
          ),
        ],
      ),
    );
  }
}
