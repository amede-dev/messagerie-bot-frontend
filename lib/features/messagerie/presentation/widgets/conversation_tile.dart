import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';

// Ligne de la liste des conversations : avatar, nom, dernier message,
// heure, badge de non-lus. Le bot utilise une icône robot dédiée

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final estBot = conversation.type == ConversationType.bot;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            estBot
                ? const AvatarCircle(icon: Icons.smart_toy_outlined)
                : AvatarCircle(
                    initiales:
                        conversation.avatarInitiales ??
                        conversation.nom.substring(0, 1),
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.nom,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conversation.dernierMessage != null)
                        Text(
                          DateFormat.Hm().format(
                            conversation.dernierMessage!.dateEnvoi,
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.enTrainDecrire
                              ? 'en train d\'écrire...'
                              : (conversation.dernierMessage?.contenu ?? ''),
                          style: TextStyle(
                            fontSize: 13,
                            color: conversation.enTrainDecrire
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontStyle: conversation.enTrainDecrire
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.nombreNonLus > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.unreadBadge,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.nombreNonLus}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
