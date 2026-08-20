import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:record/record.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/network/auth_repository.dart';
import '../../../../core/network/websocket_service.dart';
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
  final AudioRecorder _audioRecorder = AudioRecorder();

  final AuthRepository _authRepository = AuthRepository();

  bool _miseAJourLectureEnCours = false;
  bool _estEnTrainDecrire = false;
  bool _enregistrementVocal = false;
  bool _envoiVocalEnCours = false;
  String? _fichierVocalEnregistre;
  Duration _dureeVocale = Duration.zero;
  bool _positionInitialeAppliquee = false;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;
  Timer? _typingTimer;
  Timer? _timerVocal;

  String? _utilisateurCourantId;

  @override
  void initState() {
    super.initState();

    _chargerUtilisateurConnecte();
    _ecouterFrappe();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _typingTimer?.cancel();
    _typingSubscription?.cancel();
    _timerVocal?.cancel();
    _audioRecorder.dispose();

    super.dispose();
  }

  void _ecouterFrappe() {
    _typingSubscription = WebSocketService.instance.typingStream.listen((data) {
      if (!mounted ||
          data['conversationId']?.toString() != widget.conversation.id) {
        return;
      }

      _typingTimer?.cancel();
      setState(() => _estEnTrainDecrire = true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _estEnTrainDecrire = false);
      });
    });
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
      final selection = await afficherAttachmentPicker(context);

      if (selection == null) {
        return;
      }

      if (!mounted) {
        return;
      }

      final extension = selection.fichier.path.split('.').last.toLowerCase();
      final type = selection.estImage
          ? MessageType.image
          : ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension)
          ? MessageType.video
          : ['mp3', 'wav', 'm4a', 'aac', 'ogg'].contains(extension)
          ? MessageType.audio
          : MessageType.document;

      await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .envoyerFichier(selection.fichier, type);

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
    try {
      if (_enregistrementVocal || _fichierVocalEnregistre != null) return;

      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Autorisez l’accès au microphone.')),
          );
        }
        return;
      }

      final chemin =
          '${Directory.systemTemp.path}/message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: chemin,
      );
      if (mounted) {
        setState(() {
          _enregistrementVocal = true;
          _dureeVocale = Duration.zero;
        });
        _timerVocal = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted && _enregistrementVocal) {
            setState(() => _dureeVocale += const Duration(seconds: 1));
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enregistrement… Appuyez pour arrêter.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _enregistrementVocal = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d’enregistrer l’audio : $e')),
        );
      }
    }
  }

  Future<void> _arreterEnregistrementVocal() async {
    final chemin = await _audioRecorder.stop();
    _timerVocal?.cancel();
    if (!mounted) return;
    setState(() {
      _enregistrementVocal = false;
      _fichierVocalEnregistre = chemin;
    });
  }

  Future<void> _envoyerVocalEnregistre() async {
    final chemin = _fichierVocalEnregistre;
    if (chemin == null || _envoiVocalEnCours) return;

    final fichier = File(chemin);
    if (!await fichier.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le fichier vocal est introuvable.')),
        );
      }
      return;
    }

    if (mounted) setState(() => _envoiVocalEnCours = true);

    try {
      await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .envoyerFichier(fichier, MessageType.audio);

      if (!mounted) return;
      setState(() {
        _fichierVocalEnregistre = null;
        _dureeVocale = Duration.zero;
        _envoiVocalEnCours = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoiVocalEnCours = false);
      final detail = e is DioException
          ? 'HTTP ${e.response?.statusCode ?? 'inconnu'} : '
                '${e.response?.data ?? e.message}'
          : e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Échec de l’envoi vocal : $detail')),
      );
    }
  }

  Future<void> _supprimerVocalEnregistre() async {
    if (_enregistrementVocal) await _audioRecorder.stop();
    _timerVocal?.cancel();
    if (!mounted) return;
    setState(() {
      _enregistrementVocal = false;
      _fichierVocalEnregistre = null;
      _dureeVocale = Duration.zero;
    });
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
      return 'Actif';
    }

    final derniereConnexion = widget.conversation.derniereConnexion;

    if (derniereConnexion == null) {
      return 'Hors ligne';
    }

    final maintenant = DateTime.now();

    final difference = maintenant.difference(derniereConnexion);

    if (difference.inMinutes < 1) {
      return 'Hors ligne à l’instant';
    }

    if (difference.inMinutes < 60) {
      return 'Hors ligne il y a ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Hors ligne il y a ${difference.inHours} h';
    }

    return 'Hors ligne le ${DateFormat('dd/MM à HH:mm').format(derniereConnexion)}';
  }

  // ============================================================
  // MARQUER COMME LU
  // ============================================================

  Future<void> _marquerMessagesCommeLus() async {
    if (_miseAJourLectureEnCours) {
      return;
    }

    final utilisateurCourantId = _utilisateurCourantId;
    if (utilisateurCourantId == null) {
      return;
    }

    _miseAJourLectureEnCours = true;

    try {
      await ref
          .read(chatMessagesProvider(widget.conversation.id).notifier)
          .marquerMessagesEntrantsCommeLus(utilisateurCourantId);

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
                imageUrl: widget.conversation.photoUrl,
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
                      _estEnTrainDecrire ? '...' : _statutPresence(),
                      style: TextStyle(
                        fontSize: 11,
                        color: _estEnTrainDecrire
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
                final doitDefiler =
                    !_positionInitialeAppliquee ||
                    (_scrollController.hasClients &&
                        _scrollController.position.pixels >=
                            _scrollController.position.maxScrollExtent - 80);

                if (doitDefiler) {
                  _positionInitialeAppliquee = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) _scrollEnBas();
                  });
                }

                if (_utilisateurCourantId != null &&
                    messages.any(
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

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels <= 80) {
                      ref
                          .read(
                            chatMessagesProvider(
                              widget.conversation.id,
                            ).notifier,
                          )
                          .chargerMessagesPlusAnciens();
                    }
                    return false;
                  },
                  child: ListView.builder(
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
                  ),
                );
              },
            ),
          ),

          if (_estEnTrainDecrire)
            TypingIndicator(nomUtilisateur: widget.conversation.nom),

          ChatInputBar(
            onSend: _envoyerTexte,
            onTyping: _notifierFrappe,
            onGalleryTap: _choisirEtEnvoyerImage,
            onVoiceTap: _demarrerMessageVocal,
            enregistrementVocal:
                _enregistrementVocal || _fichierVocalEnregistre != null,
            vocalEnCours: _enregistrementVocal,
            dureeVocale: _dureeVocale,
            onStopVocal: _arreterEnregistrementVocal,
            onDeleteVocal: _supprimerVocalEnregistre,
            onSendVocal: _envoyerVocalEnregistre,
            envoiVocalEnCours: _envoiVocalEnCours,
          ),
        ],
      ),
    );
  }
}
