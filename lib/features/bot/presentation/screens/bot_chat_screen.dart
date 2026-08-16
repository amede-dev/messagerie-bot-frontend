import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../messagerie/presentation/widgets/chat_input_bar.dart';
import '../../../messagerie/presentation/widgets/message_bubble.dart';
import '../../providers/bot_providers.dart';
import '../widgets/quick_reply_chip.dart';

// Écran de discussion dédié à l'assistant (Bot).
// Le badge "Bot · toujours disponible" garantit qu'il ne soit jamais.
class BotChatScreen extends ConsumerWidget {
  const BotChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(botChatProvider);
    final notifier = ref.read(botChatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.smart_toy_outlined, size: 16),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Assistant Uni',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Bot · toujours disponible',
                  style: TextStyle(fontSize: 11, color: AppColors.success),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final estDernier = index == entries.length - 1;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MessageBubble(
                      message: entry.message,
                      estUtilisateurCourant: entry.message.expediteurId == 'me',
                    ),
                    if (estDernier && entry.suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4,
                          left: 4,
                          bottom: 8,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: entry.suggestions
                              .map(
                                (s) => QuickReplyChip(
                                  texte: s,
                                  onTap: () => notifier.envoyer(s),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          ChatInputBar(onSend: notifier.envoyer),
        ],
      ),
    );
  }
}
