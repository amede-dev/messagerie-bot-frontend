import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/models/message_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';

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
    final alignement = estUtilisateurCourant
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

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

      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),

          child: Align(
            alignment: estUtilisateurCourant
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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

                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!estUtilisateurCourant) ...[
                      AvatarCircle(
                        initiales: message.expediteurNom.isNotEmpty
                            ? message.expediteurNom.substring(0, 1)
                            : '?',
                        imageUrl: message.expediteurPhotoUrl,
                        size: 28,
                      ),
                      const SizedBox(width: 6),
                    ],
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.70,
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
                  ],
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
        return _image(context);

      case MessageType.video:
        return _video();

      case MessageType.audio:
        return _audio();

      case MessageType.document:
        return _document(context, couleurTexte);

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

  Widget _image(BuildContext context) {
    final url = AppConfig.resolveMediaUrl(message.contenu)!;
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            url,

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
        ),
        _downloadButton(context, url, 'image'),
      ],
    );
  }

  Widget _downloadButton(BuildContext context, String url, String type) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: 'Télécharger',
          icon: const Icon(Icons.download, color: Colors.white, size: 20),
          onPressed: () => _telecharger(context, url, type),
        ),
      ),
    );
  }

  Future<void> _telecharger(
    BuildContext context,
    String url,
    String type,
  ) async {
    try {
      final response = await ApiClient.instance.dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final nom = Uri.parse(url).pathSegments.last.isEmpty
          ? 'fichier_$type'
          : Uri.parse(url).pathSegments.last;
      final chemin = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le fichier',
        fileName: nom,
        bytes: Uint8List.fromList(response.data ?? const <int>[]),
      );
      if (chemin != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Fichier téléchargé.')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Téléchargement impossible : $error')),
        );
      }
    }
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

  Widget _document(BuildContext context, Color couleurTexte) {
    final nom = message.contenu.split('/').last;
    final url = AppConfig.resolveMediaUrl(message.contenu)!;

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
          IconButton(
            tooltip: 'Télécharger',
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _telecharger(context, url, 'document'),
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
  Duration _position = Duration.zero;
  Duration _duree = Duration.zero;
  late final StreamSubscription<Duration> _positionSubscription;
  late final StreamSubscription<Duration> _dureeSubscription;
  late final StreamSubscription<void> _completeSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.onPositionChanged.listen((value) {
      if (mounted) setState(() => _position = value);
    });
    _dureeSubscription = _player.onDurationChanged.listen((value) {
      if (mounted) setState(() => _duree = value);
    });
    _completeSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _lecture = false;
          _position = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _positionSubscription.cancel();
    _dureeSubscription.cancel();
    _completeSubscription.cancel();
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

    try {
      final url = AppConfig.resolveMediaUrl(widget.url) ?? widget.url;
      final response = await ApiClient.instance.dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final octets = response.data;
      if (octets == null || octets.isEmpty) {
        throw StateError('Le fichier vocal est vide.');
      }

      final extension = Uri.parse(url).path.split('.').last.toLowerCase();
      final mimeType = switch (extension) {
        'mp3' => 'audio/mpeg',
        'wav' => 'audio/wav',
        'aac' => 'audio/aac',
        'ogg' => 'audio/ogg',
        'm4a' => 'audio/mp4',
        _ => 'audio/mp4',
      };

      await _player.play(
        BytesSource(Uint8List.fromList(octets), mimeType: mimeType),
      );

      if (mounted) setState(() => _lecture = true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de lire le vocal : $error')),
      );
    }
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

          Expanded(
            child: Slider(
              min: 0,
              max: _duree.inMilliseconds > 0
                  ? _duree.inMilliseconds.toDouble()
                  : 1,
              value: _position.inMilliseconds
                  .clamp(
                    0,
                    _duree.inMilliseconds > 0 ? _duree.inMilliseconds : 1,
                  )
                  .toDouble(),
              onChanged: (value) =>
                  _player.seek(Duration(milliseconds: value.round())),
            ),
          ),
          IconButton(
            tooltip: 'Arrêter',
            icon: const Icon(Icons.stop_circle_outlined),
            onPressed: () async {
              await _player.stop();
              if (mounted) {
                setState(() {
                  _lecture = false;
                  _position = Duration.zero;
                });
              }
            },
          ),
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
