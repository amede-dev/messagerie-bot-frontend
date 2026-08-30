import 'package:flutter/material.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/message_date_formatter.dart';
import '../../../../shared/widgets/avatar_circle.dart';

// Ligne de la liste des conversations

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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
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
                      imageUrl: conversation.photoUrl,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  conversation.nom,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    fontWeight: estNonLu
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (conversation.estEnLigne) ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (conversation.dernierMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              MessageDateFormatter.format(
                                conversation.dernierMessage!.dateEnvoi,
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: estNonLu
                                    ? AppColors.primary
                                    : AppColors.textMuted,
                                fontWeight: estNonLu
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
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
                              fontSize: estNonLu ? 14 : 13,
                              color: conversation.enTrainDecrire
                                  ? AppColors.primary
                                  : (estNonLu
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary),
                              fontStyle: conversation.enTrainDecrire
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              fontWeight: estNonLu
                                  ? FontWeight.w700
                                  : FontWeight.w400,
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
      ),
    );
  }
}
