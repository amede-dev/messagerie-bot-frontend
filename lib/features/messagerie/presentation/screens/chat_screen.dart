import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/network/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/attachment_picker_sheet.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'conversation_settings_screen.dart';
import 'forward_message_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  final AuthRepository _authRepository = AuthRepository();

  bool _miseAJourLectureEnCours = false;

  String? _utilisateurCourantId;

  @override
  void initState() {
    super.initState();

    _chargerUtilisateurConnecte();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  // ============================================================
  // UTILISATEUR CONNECTÉ
  // ============================================================

  Future<void> _chargerUtilisateurConnecte() async {
    final id = await _authRepository.idUtilisateurConnecte();

    if (!mounted) return;

    setState(() {
      _utilisateurCourantId = id;
    });
  }

  // ============================================================
  // SCROLL
  // ============================================================

  void _scrollEnBas({bool anime = true}) {
    if (!_scrollController.hasClients) {
      return;
    }

    final position = _scrollController.position.maxScrollExtent;

    if (anime) {
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(position);
    }
  }

  // ============================================================
  // GALERIE
  // ============================================================

  Future<void> _choisirEtEnvoyerImage() async {
    try {
      final selection = await choisirImageDepuisGalerie();

      if (selection == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .envoyerFichier(
            selection.fichier,
            selection.estImage ? MessageType.image : MessageType.document,
          );

      if (mounted) {
        _scrollEnBas();
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’envoyer le fichier : $e')),
      );
    }
  }

  // ============================================================
  // MESSAGE VOCAL
  // ============================================================

  Future<void> _demarrerMessageVocal() async {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'L’enregistrement vocal sera disponible '
          'après le raccordement au serveur.',
        ),
      ),
    );
  }

  // ============================================================
  // ACTION NON DISPONIBLE
  // ============================================================

  void _annoncerAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action sera disponible prochainement.')),
    );
  }

  // ============================================================
  // PRÉSENCE
  // ============================================================

  String _statutPresence() {
    if (widget.conversation.estEnLigne) {
      return 'En ligne';
    }

    final derniereConnexion = widget.conversation.derniereConnexion;

    if (derniereConnexion == null) {
      return 'Hors ligne';
    }

    final maintenant = DateTime.now();

    final difference = maintenant.difference(derniereConnexion);

    if (difference.inMinutes < 1) {
      return 'Vu à l’instant';
    }

    if (difference.inMinutes < 60) {
      return 'Vu il y a ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Vu il y a ${difference.inHours} h';
    }

    return 'Vu le ${DateFormat('dd/MM à HH:mm').format(derniereConnexion)}';
  }

  // ============================================================
  // MARQUER COMME LU
  // ============================================================

  Future<void> _marquerMessagesCommeLus() async {
    if (_miseAJourLectureEnCours) {
      return;
    }

    _miseAJourLectureEnCours = true;

    try {
      await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .marquerMessagesEntrantsCommeLus(_utilisateurCourantId);

      ref
          .read(conversationListProvider.notifier)
          .marquerConversationLue(widget.conversation.id);
    } finally {
      _miseAJourLectureEnCours = false;
    }
  }

  // ============================================================
  // ACTION MESSAGE
  // ============================================================

  Future<void> _ouvrirActionsMessage(
    MessageModel message,
    bool estUtilisateurCourant,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_outlined),
                title: const Text('Copier'),
                onTap: () {
                  Navigator.of(context).pop('copier');
                },
              ),

              ListTile(
                leading: const Icon(Icons.forward_outlined),
                title: const Text('Transférer'),
                onTap: () {
                  Navigator.of(context).pop('transferer');
                },
              ),

              if (estUtilisateurCourant)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.danger,
                  ),
                  title: const Text(
                    'Supprimer',
                    style: TextStyle(color: AppColors.danger),
                  ),
                  onTap: () {
                    Navigator.of(context).pop('supprimer');
                  },
                ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    // COPIER
    if (action == 'copier') {
      await Clipboard.setData(ClipboardData(text: message.contenu));

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message copié.')));

      return;
    }

    // TRANSFÉRER
    if (action == 'transferer') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ForwardMessageScreen(message: message),
        ),
      );

      return;
    }

    // SUPPRIMER
    if (action == 'supprimer') {
      await _choisirSuppressionMessage(message);
    }
  }

  // ============================================================
  // SUPPRESSION MESSAGE
  // ============================================================

  Future<void> _choisirSuppressionMessage(MessageModel message) async {
    final portee = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Supprimer pour moi'),
                onTap: () {
                  Navigator.of(context).pop('moi');
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: AppColors.danger,
                ),
                title: const Text(
                  'Supprimer pour tout le monde',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Navigator.of(context).pop('tous');
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || portee == null) {
      return;
    }

    final messages = ref.read(
      chatMessagesProvider(widget.conversation.id).notifier,
    );

    // POUR MOI
    if (portee == 'moi') {
      messages.supprimerMessageLocalement(message.id);

      return;
    }

    // POUR TOUS
    try {
      await ref
          .read(conversationRepositoryProvider)
          .supprimerMessagePourTous(message.id);

      messages.supprimerMessageLocalement(message.id);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La suppression pour tous nécessite '
            'la mise à jour du serveur.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // ENVOYER TEXTE
  // ============================================================

  void _envoyerTexte(String texte) {
    final texteNettoye = texte.trim();

    if (texteNettoye.isEmpty) {
      return;
    }

    ref
        .read(chatMessagesProvider(widget.conversation.id).notifier)
        .envoyer(texteNettoye);

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollEnBas());
  }

  // ============================================================
  // TYPING
  // ============================================================

  void _notifierFrappe() {
    ref
        .read(chatMessagesProvider(widget.conversation.id).notifier)
        .notifierFrappe();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversation.id),
    );

    final estGroupe = widget.conversation.type == ConversationType.groupe;

    return Scaffold(
      // ==========================================================
      // APP BAR
      // ==========================================================
      appBar: AppBar(
        titleSpacing: 0,

        title: InkWell(
          borderRadius: BorderRadius.circular(24),

          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ConversationSettingsScreen(
                  conversation: widget.conversation,
                ),
              ),
            );
          },

          child: Row(
            children: [
              AvatarCircle(
                initiales:
                    widget.conversation.avatarInitiales ??
                    (widget.conversation.nom.isNotEmpty
                        ? widget.conversation.nom.substring(0, 1)
                        : '?'),

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
            tooltip: 'Options',
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationSettingsScreen(
                    conversation: widget.conversation,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ==========================================================
      // BODY
      // ==========================================================
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              // CHARGEMENT
              loading: () {
                return const Center(child: CircularProgressIndicator());
              },

              // ERREUR
              error: (err, _) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text('Erreur : $err', textAlign: TextAlign.center),
                  ),
                );
              },

              // DONNÉES
              data: (messages) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollEnBas();
                  }
                });

                if (messages.any(
                  (message) =>
                      message.expediteurId != _utilisateurCourantId &&
                      message.statut != MessageStatut.lu,
                )) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _marquerMessagesCommeLus();
                  });
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun message',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
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

                    final estUtilisateurCourant =
                        message.expediteurId == _utilisateurCourantId;

                    return MessageBubble(
                      message: message,
                      estUtilisateurCourant: estUtilisateurCourant,
                      afficherNomExpediteur: estGroupe,
                      onLongPress: () {
                        _ouvrirActionsMessage(message, estUtilisateurCourant);
                      },
                    );
                  },
                );
              },
            ),
          ),

          if (widget.conversation.enTrainDecrire)
            TypingIndicator(nomUtilisateur: widget.conversation.nom),

          ChatInputBar(
            onSend: _envoyerTexte,
            onTyping: _notifierFrappe,
            onGalleryTap: _choisirEtEnvoyerImage,
            onVoiceTap: _demarrerMessageVocal,
          ),
        ],
      ),
    );
  }
}
