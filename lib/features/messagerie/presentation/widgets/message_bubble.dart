import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/message_model.dart';
import '../../../../core/theme/app_theme.dart';

// Bulle de message alignée à droite (utilisateur courant) ou à gauche
// avec nom de l'expéditeur pour les groupes et statut

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool estUtilisateurCourant;
  final bool afficherNomExpediteur;

  const MessageBubble({
    super.key,
    required this.message,
    required this.estUtilisateurCourant,
    this.afficherNomExpediteur = false,
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
      bottomLeft: Radius.circular(estUtilisateurCourant ? AppTheme.radiusM : 4),
      bottomRight: Radius.circular(
        estUtilisateurCourant ? 4 : AppTheme.radiusM,
      ),
    );

    return Padding(
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: couleurFond,
                borderRadius: radius,
              ),
              child: Text(
                message.contenu,
                style: TextStyle(fontSize: 14, color: couleurTexte),
              ),
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

  Color _couleurStatut(MessageStatut statut) =>
      statut == MessageStatut.lu ? AppColors.primary : AppColors.textMuted;
}
