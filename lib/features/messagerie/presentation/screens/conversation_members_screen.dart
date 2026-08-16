import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';

// Écran "Voir les membres" — accessible depuis les paramètres d'un groupe.
// Données factices en attendant l'endpoint réel
// GET /api/conversations/{id}/participants côté backend.
class ConversationMembersScreen extends StatelessWidget {
  final String conversationNom;

  const ConversationMembersScreen({super.key, required this.conversationNom});

  // TODO: remplacer par un vrai appel API listant les ConversationParticipant
  static const _membres = [
    {'initiales': 'HR', 'nom': 'Hery Rakoto', 'role': 'Admin'},
    {'initiales': 'CI', 'nom': 'Claudine Ihanta', 'role': 'Membre'},
    {'initiales': 'MJ', 'nom': 'Mamy Joel', 'role': 'Membre'},
    {'initiales': 'moi', 'nom': 'Moi', 'role': 'Membre'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Membres · $conversationNom')),
      body: ListView.separated(
        itemCount: _membres.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final membre = _membres[index];
          return ListTile(
            leading: AvatarCircle(initiales: membre['initiales']!),
            title: Text(membre['nom']!),
            trailing: membre['role'] == 'Admin'
                ? const Text(
                    'Admin',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  )
                : null,
          );
        },
      ),
    );
  }
}
