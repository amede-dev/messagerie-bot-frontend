import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
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
  bool _miseAJourLectureEnCours = false;

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

  /// Ouvre directement la galerie native, comme dans les messageries.
  Future<void> _choisirEtEnvoyerImage() async {
    final selection = await choisirImageDepuisGalerie();
    if (selection == null) return; // utilisateur a annulé

    ref
        .read(chatMessagesProvider(widget.conversation.id).notifier)
        .envoyerPieceJointe(selection.fichier, estImage: selection.estImage);
  }

  void _demarrerMessageVocal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('L’enregistrement vocal sera disponible prochainement.'),
      ),
    );
  }

  void _annoncerAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action sera disponible prochainement.')),
    );
  }

  String _statutPresence() {
    if (widget.conversation.estEnLigne) return 'En ligne';
    final derniereActivite = widget.conversation.dernierMessage?.dateEnvoi;
    if (derniereActivite == null) return 'Hors ligne';
    return 'Vu le ${DateFormat('dd/MM à HH:mm').format(derniereActivite)}';
  }

  Future<void> _marquerMessagesCommeLus() async {
    if (_miseAJourLectureEnCours) return;
    _miseAJourLectureEnCours = true;
    try {
      await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .marquerMessagesRecusCommeLus();
      ref
          .read(conversationListProvider.notifier)
          .marquerConversationLue(widget.conversation.id);
    } finally {
      _miseAJourLectureEnCours = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversation.id),
    );
    final estGroupe = widget.conversation.type == ConversationType.groupe;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ConversationSettingsScreen(conversation: widget.conversation),
            ),
          ),
          child: Row(
            children: [
              AvatarCircle(
                initiales:
                    widget.conversation.avatarInitiales ??
                    widget.conversation.nom.substring(0, 1),
                size: 38,
                estEnLigne:
                    widget.conversation.type == ConversationType.privee &&
                    widget.conversation.estEnLigne,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.conversation.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _statutPresence(),
                      style: TextStyle(
                        fontSize: 11,
                        color: widget.conversation.enTrainDecrire
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Appeler',
            icon: const Icon(Icons.call_outlined),
            onPressed: () => _annoncerAction('L’appel audio'),
          ),
          IconButton(
            tooltip: 'Appel vidéo',
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () => _annoncerAction('L’appel vidéo'),
          ),
          IconButton(
            tooltip: 'Paramètres de la discussion',
            icon: const Icon(Icons.settings_outlined),
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
                if (messages.any(
                  (message) => message.statut == MessageStatut.recu,
                )) {
                  WidgetsBinding.instance.addPostFrameCallback(
                    (_) => _marquerMessagesCommeLus(),
                  );
                }
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
            onGalleryTap: _choisirEtEnvoyerImage,
            onVoiceTap: _demarrerMessageVocal,
          ),
        ],
      ),
    );
  }
}
