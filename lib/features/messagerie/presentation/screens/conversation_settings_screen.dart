import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';
import 'shared_media_screen.dart';

class ConversationSettingsScreen extends ConsumerStatefulWidget {
  const ConversationSettingsScreen({super.key, required this.conversation});

  final ConversationModel conversation;

  @override
  ConsumerState<ConversationSettingsScreen> createState() =>
      _ConversationSettingsScreenState();
}

class _ConversationSettingsScreenState
    extends ConsumerState<ConversationSettingsScreen> {
  bool _enCours = false;

  // INFORMATION

  void _informer(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // BLOQUER

  Future<void> _confirmerBlocage() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bloquer ${widget.conversation.nom} ?'),

        content: const Text(
          'Cette action empêchera cette personne '
          'de vous envoyer de nouveaux messages.',
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),

            onPressed: () => Navigator.of(context).pop(true),

            child: const Text('Bloquer'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) {
      return;
    }

    _informer(
      'Le blocage sera activé dès que '
      'l’API de profil sera disponible.',
    );
  }

  // SUPPRIMER / QUITTER

  Future<void> _supprimerConversation() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation ?'),

        content: const Text('Cette conversation sera retirée de votre liste.'),

        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),

          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),

            onPressed: () => Navigator.of(context).pop(true),

            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) {
      return;
    }

    setState(() {
      _enCours = true;
    });

    try {
      await ref
          .read(conversationRepositoryProvider)
          .quitterConversation(widget.conversation.id);

      ref
          .read(conversationListProvider.notifier)
          .retirerConversation(widget.conversation.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _enCours = false;
      });

      _informer('Impossible de réaliser cette action pour le moment.');
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final nom = widget.conversation.nom;

    return Scaffold(
      appBar: AppBar(),

      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),

        children: [
          const SizedBox(height: 12),

          Center(
            child: AvatarCircle(
              initiales:
                  widget.conversation.avatarInitiales ??
                  (nom.isNotEmpty ? nom.substring(0, 1) : '?'),
              imageUrl: widget.conversation.photoUrl,
              size: 84,
            ),
          ),

          const SizedBox(height: 12),

          Center(
            child: Text(
              nom,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),

          const SizedBox(height: 6),

          ..._optionsPrivees(nom),
        ],
      ),
    );
  }

  List<Widget> _optionsPrivees(String nom) => [
    const _TitreSection('Actions'),

    _Option(
      icon: _enCours ? Icons.hourglass_top : Icons.delete_outline,
      titre: 'Supprimer la conversation',
      danger: true,
      onTap: _enCours ? null : _supprimerConversation,
    ),
  ];
}

// TITRE SECTION

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.titre);

  final String titre;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),

      child: Text(
        titre,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

// RACCOURCI

class _Raccourci extends StatelessWidget {
  const _Raccourci({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;

  final String label;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,

      child: InkWell(
        borderRadius: BorderRadius.circular(28),

        onTap: onTap,

        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryLight,

              child: Icon(icon, color: AppColors.primary),
            ),

            const SizedBox(height: 6),

            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,

              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

// OPTION

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.titre,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;

  final String titre;

  final VoidCallback? onTap;

  final bool danger;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,

      leading: CircleAvatar(
        radius: 18,

        backgroundColor: danger
            ? AppColors.primaryLight
            : AppColors.primaryLight,

        child: Icon(
          icon,
          size: 19,
          color: danger ? AppColors.danger : AppColors.primary,
        ),
      ),

      title: Text(
        titre,
        style: TextStyle(color: danger ? AppColors.danger : null),
      ),

      onTap: onTap,
    );
  }
}
