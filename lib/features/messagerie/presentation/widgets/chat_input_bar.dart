import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Barre de saisie en bas de l'écran de chat : pièce jointe, champ texte, bouton d'envoi, galerie et vocal.

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onVoiceTap;
  final bool afficherActionsMedia;
  final bool enregistrementVocal;
  final bool vocalEnCours;
  final Duration dureeVocale;
  final VoidCallback? onStopVocal;
  final VoidCallback? onDeleteVocal;
  final VoidCallback? onSendVocal;
  final bool envoiVocalEnCours;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onTyping,
    this.onGalleryTap,
    this.onVoiceTap,
    this.afficherActionsMedia = true,
    this.enregistrementVocal = false,
    this.vocalEnCours = false,
    this.dureeVocale = Duration.zero,
    this.onStopVocal,
    this.onDeleteVocal,
    this.onSendVocal,
    this.envoiVocalEnCours = false,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();

  void _envoyer() {
    final texte = _controller.text.trim();
    if (texte.isEmpty) return;
    widget.onSend(texte);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: widget.enregistrementVocal
            ? _barreVocale()
            : Row(
                children: [
                  if (widget.afficherActionsMedia) ...[
                    IconButton(
                      tooltip: 'Galerie',
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: widget.onGalleryTap,
                    ),
                    IconButton(
                      tooltip: 'Message vocal',
                      icon: const Icon(
                        Icons.mic_none_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: widget.onVoiceTap,
                    ),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onChanged: (_) => widget.onTyping?.call(),
                      onSubmitted: (_) => _envoyer(),
                      style: const TextStyle(color: AppColors.textPrimary),
                      cursorColor: AppColors.primary,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        hintStyle: const TextStyle(
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.primary),
                    onPressed: _envoyer,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _barreVocale() {
    final secondes = widget.dureeVocale.inSeconds;
    final temps =
        '${secondes ~/ 60}:${(secondes % 60).toString().padLeft(2, '0')}';

    return Row(
      children: [
        IconButton(
          tooltip: 'Supprimer le vocal',
          onPressed: widget.onDeleteVocal,
          icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
        ),
        Expanded(
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.vocalEnCours
                        ? '●  Enregistrement…'
                        : 'Vocal prêt à envoyer',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  temps,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Arrêter le vocal',
          onPressed: widget.vocalEnCours ? widget.onStopVocal : null,
          icon: Icon(
            widget.vocalEnCours ? Icons.stop : Icons.check,
            color: widget.vocalEnCours
                ? AppColors.primary
                : AppColors.textMuted,
          ),
        ),
        IconButton(
          tooltip: 'Envoyer le vocal',
          onPressed: widget.vocalEnCours || widget.envoiVocalEnCours
              ? null
              : widget.onSendVocal,
          icon: widget.envoiVocalEnCours
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, color: AppColors.primary),
        ),
      ],
    );
  }
}
