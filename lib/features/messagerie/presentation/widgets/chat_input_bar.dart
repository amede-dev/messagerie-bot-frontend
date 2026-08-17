import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Barre de saisie en bas de l'écran de chat : pièce jointe, champ texte,
// bouton d'envoi, galerie et vocal.

class ChatInputBar extends StatefulWidget {
  final ValueChanged<String> onSend;
  final VoidCallback? onTyping;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onVoiceTap;

  const ChatInputBar({
    super.key,
    required this.onSend,
    this.onTyping,
    this.onGalleryTap,
    this.onVoiceTap,
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
        child: Row(
          children: [
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
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (_) => widget.onTyping?.call(),
                onSubmitted: (_) => _envoyer(),
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  hintText: 'Écrire un message...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.black,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
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
}
