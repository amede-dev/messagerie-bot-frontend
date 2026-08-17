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
  final VoidCallback? onLongPress;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final estBot = conversation.type == ConversationType.bot;
    final estNonLu = conversation.nombreNonLus > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
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
                    estEnLigne:
                        conversation.type == ConversationType.privee &&
                        conversation.estEnLigne,
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
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight:
                              estNonLu ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (conversation.dernierMessage != null)
                        Text(
                          DateFormat.Hm().format(
                            conversation.dernierMessage!.dateEnvoi,
                          ),
                          style: TextStyle(
                            fontSize: 12,
                            color: estNonLu
                                ? AppColors.primary
                                : AppColors.textMuted,
                            fontWeight:
                                estNonLu ? FontWeight.w700 : FontWeight.w400,
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
                                : (estNonLu
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary),
                            fontStyle: conversation.enTrainDecrire
                                ? FontStyle.italic
                                : FontStyle.normal,
                            fontWeight:
                                estNonLu ? FontWeight.w700 : FontWeight.w400,
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
