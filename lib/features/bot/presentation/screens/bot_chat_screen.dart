import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/message_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/uni_logo.dart';
import '../../../messagerie/presentation/widgets/chat_input_bar.dart';
import '../../../messagerie/presentation/widgets/message_bubble.dart';
import '../../providers/bot_providers.dart';
import '../widgets/quick_reply_chip.dart';

// Écran de discussion avec l'assistant "Uni AI"
class BotChatScreen extends ConsumerWidget {
  const BotChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(botChatProvider);
    final notifier = ref.read(botChatProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: const [
            SizedBox(width: 4),
            UniLogo(size: 30),
            SizedBox(width: 10),
            Text(
              'Uni AI',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            SizedBox(width: 4),
            Icon(Icons.verified, size: 15, color: AppColors.primary),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: entries.isEmpty
                ? const _UniEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final estDernier = index == entries.length - 1;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          MessageBubble(
                            message: entry.message,
                            estUtilisateurCourant:
                                entry.message.expediteurId == 'me',
                            onLongPress: () =>
                                _ouvrirActionsMessage(context, entry.message),
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
          if (entries.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                border: Border(top: BorderSide(color: AppColors.primary)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Session transférée à un conseiller humain',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ChatInputBar(onSend: notifier.envoyer, afficherActionsMedia: false),
        ],
      ),
    );
  }

  Future<void> _ouvrirActionsMessage(
    BuildContext context,
    MessageModel message,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.copy_outlined),
          title: const Text('Copier'),
          onTap: () => Navigator.of(context).pop('copier'),
        ),
      ),
    );

    if (action != 'copier' || !context.mounted) return;

    await Clipboard.setData(ClipboardData(text: message.contenu));
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Message copié')));
  }
}

// Écran d'accueil affiché
class _UniEmptyState extends StatelessWidget {
  const _UniEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UniLogo(size: 96),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Uni AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 6),
                Icon(Icons.verified, size: 18, color: AppColors.primary),
              ],
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(
                    text:
                        'Les messages sont générés par l\'IA. Certains '
                        'peuvent être inexacts ou inappropriés. ',
                  ),
                  TextSpan(
                    text: 'En savoir plus.',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'En utilisant Uni AI, vous acceptez les Conditions générales '
              'de l\'assistant. Vos messages avec l\'IA pourront être '
              'utilisés pour améliorer Uni.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
