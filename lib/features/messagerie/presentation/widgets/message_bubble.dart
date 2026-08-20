import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/message_model.dart';
import '../../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;

  final bool estUtilisateurCourant;

  final bool afficherNomExpediteur;

  final VoidCallback? onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.estUtilisateurCourant,
    this.afficherNomExpediteur = false,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Les messages privés sont volontairement regroupés à droite,
    // qu'ils soient envoyés par Amedé ou par Bernard.
    const alignement = CrossAxisAlignment.end;

    final couleurFond = estUtilisateurCourant
        ? AppColors.primary
        : AppColors.bubbleReceived;

    final couleurTexte = estUtilisateurCourant
        ? Colors.white
        : AppColors.textPrimary;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppTheme.radiusM),

      topRight: const Radius.circular(AppTheme.radiusM),

      bottomLeft: Radius.circular(estUtilisateurCourant ? 4 : AppTheme.radiusM),

      bottomRight: Radius.circular(
        estUtilisateurCourant ? AppTheme.radiusM : 4,
      ),
    );

    return InkWell(
      onLongPress: onLongPress,

      borderRadius: radius,

      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),

        child: Column(
          crossAxisAlignment: alignement,

          children: [
            if (afficherNomExpediteur && !estUtilisateurCourant)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 2),

                child: Text(
                  message.expediteurNom,

                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78,
              ),

              child: Container(
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: couleurFond,

                  borderRadius: radius,
                ),

                child: _contenuMessage(context, couleurTexte),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 2, left: 4, right: 4),

              child: Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  Text(
                    DateFormat.Hm().format(message.dateEnvoi),

                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),

                  if (estUtilisateurCourant) ...[
                    const SizedBox(width: 3),

                    Icon(
                      _iconeStatut(message.statut),

                      size: 14,

                      color: _couleurStatut(message.statut),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // CONTENU
  // ==========================================================================

  Widget _contenuMessage(BuildContext context, Color couleurTexte) {
    switch (message.type) {
      case MessageType.texte:
        return Text(
          message.contenu,
          style: TextStyle(fontSize: 14, color: couleurTexte),
        );

      case MessageType.image:
        return _image();

      case MessageType.video:
        return _video();

      case MessageType.audio:
        return _audio();

      case MessageType.document:
        return _document(couleurTexte);

      case MessageType.systeme:
        return Text(
          message.contenu,
          style: TextStyle(fontSize: 14, color: couleurTexte),
        );
    }
  }

  // ==========================================================================
  // IMAGE
  // ==========================================================================

  Widget _image() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),

      child: Image.network(
        message.contenu,

        width: 240,

        height: 240,

        fit: BoxFit.cover,

        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return const SizedBox(
            width: 240,
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        },

        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            width: 240,
            height: 150,

            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.broken_image_outlined, size: 40),

                  SizedBox(height: 8),

                  Text('Impossible de charger l’image'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // VIDEO
  // ==========================================================================

  Widget _video() {
    return VideoMessagePlayer(url: message.contenu);
  }

  // ==========================================================================
  // AUDIO
  // ==========================================================================

  Widget _audio() {
    return AudioMessagePlayer(url: message.contenu);
  }

  // ==========================================================================
  // DOCUMENT
  // ==========================================================================

  Widget _document(Color couleurTexte) {
    final nom = message.contenu.split('/').last;

    return SizedBox(
      width: 230,

      child: Row(
        children: [
          const Icon(Icons.description_outlined, size: 36),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              nom,

              maxLines: 2,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: couleurTexte,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconeStatut(MessageStatut statut) {
    switch (statut) {
      case MessageStatut.enAttente:
        return Icons.access_time;

      case MessageStatut.envoye:
        return Icons.check;

      case MessageStatut.recu:
      case MessageStatut.lu:
        return Icons.done_all;
    }
  }

  Color _couleurStatut(MessageStatut statut) {
    return statut == MessageStatut.lu ? AppColors.primary : AppColors.textMuted;
  }
}

// =============================================================================
// LECTEUR AUDIO
// =============================================================================

class AudioMessagePlayer extends StatefulWidget {
  final String url;

  const AudioMessagePlayer({super.key, required this.url});

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();

  bool _lecture = false;

  @override
  void dispose() {
    _player.dispose();

    super.dispose();
  }

  Future<void> _basculerLecture() async {
    if (_lecture) {
      await _player.pause();

      if (mounted) {
        setState(() => _lecture = false);
      }

      return;
    }

    await _player.play(UrlSource(widget.url));

    if (mounted) {
      setState(() => _lecture = true);
    }

    _player.onPlayerComplete.first.then((_) {
      if (mounted) {
        setState(() => _lecture = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,

      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _lecture ? Icons.pause_circle_filled : Icons.play_circle_fill,

              size: 40,
            ),

            onPressed: _basculerLecture,
          ),

          const Expanded(child: Text('Message vocal')),
        ],
      ),
    );
  }
}

// =============================================================================
// LECTEUR VIDEO
// =============================================================================

class VideoMessagePlayer extends StatefulWidget {
  final String url;

  const VideoMessagePlayer({super.key, required this.url});

  @override
  State<VideoMessagePlayer> createState() => _VideoMessagePlayerState();
}

class _VideoMessagePlayerState extends State<VideoMessagePlayer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        width: 240,
        height: 180,

        child: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },

      child: SizedBox(
        width: 240,

        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,

          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}
