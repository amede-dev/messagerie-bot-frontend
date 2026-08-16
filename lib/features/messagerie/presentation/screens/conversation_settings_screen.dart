import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';
import 'conversation_members_screen.dart';
import 'shared_media_screen.dart';

// Écran de paramètres d'une conversation : notifications, médias,
// membres, signalement, quitter le groupe.
class ConversationSettingsScreen extends ConsumerStatefulWidget {
  final ConversationModel conversation;

  const ConversationSettingsScreen({super.key, required this.conversation});

  @override
  ConsumerState<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState
    extends ConsumerState<ConversationSettingsScreen> {
  bool _notificationsActivees = true;
  bool _enCours = false;

  Future<void> _signaler() async {
    // TODO: ouvrir un formulaire de motif avant l'appel réel
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Conversation signalée à la modération')),
    );
  }

  Future<void> _quitterLeGroupe() async {
    final estGroupe = widget.conversation.type == ConversationType.groupe;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          estGroupe ? 'Quitter le groupe ?' : 'Quitter la conversation ?',
        ),
        content: Text(
          estGroupe
              ? 'Tu ne recevras plus les messages de "${widget.conversation.nom}". '
                    'Un administrateur devra te réinviter pour revenir.'
              : 'Cette conversation sera retirée de ta liste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Quitter',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    setState(() => _enCours = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // 1. Appel backend (no-op en mode mock, voir AppConfig.useMockBackend)
      await ref
          .read(conversationRepositoryProvider)
          .quitterConversation(widget.conversation.id);
      // 2. Retrait immédiat de la liste affichée (fonctionne aussi en mock)
      ref
          .read(conversationListProvider.notifier)
          .retirerConversation(widget.conversation.id);
      // 3. Retour direct à l'écran d'accueil de la messagerie
      navigator.popUntil((route) => route.isFirst);
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Impossible de quitter le groupe pour le moment.'),
        ),
      );
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estGroupe = widget.conversation.type == ConversationType.groupe;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                AvatarCircle(
                  initiales:
                      widget.conversation.avatarInitiales ??
                      widget.conversation.nom.substring(0, 1),
                  size: 64,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.conversation.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            value: _notificationsActivees,
            onChanged: (val) => setState(() => _notificationsActivees = val),
          ),
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: const Text('Médias partagés'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    SharedMediaScreen(conversationNom: widget.conversation.nom),
              ),
            ),
          ),
          if (estGroupe)
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Voir les membres'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConversationMembersScreen(
                    conversationNom: widget.conversation.nom,
                  ),
                ),
              ),
            ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.flag_outlined, color: AppColors.danger),
            title: const Text(
              'Signaler',
              style: TextStyle(color: AppColors.danger),
            ),
            onTap: _signaler,
          ),
          ListTile(
            leading: _enCours
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, color: AppColors.danger),
            title: Text(
              estGroupe ? 'Quitter le groupe' : 'Quitter la conversation',
              style: const TextStyle(color: AppColors.danger),
            ),
            onTap: _enCours ? null : _quitterLeGroupe,
          ),
        ],
      ),
    );
  }
}
