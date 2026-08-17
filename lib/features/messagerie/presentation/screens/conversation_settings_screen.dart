import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/attachment_picker_sheet.dart';
import 'conversation_members_screen.dart';
import 'new_conversation_screen.dart';
import 'shared_media_screen.dart';

/// Profil et options d'une discussion, inspirés des messageries modernes.
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
  late String _nomGroupe;

  bool get _estGroupe => widget.conversation.type == ConversationType.groupe;

  @override
  void initState() {
    super.initState();
    _nomGroupe = widget.conversation.nom;
  }

  void _informer(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmerBlocage() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bloquer ${widget.conversation.nom} ?'),
        content: const Text(
          'Cette action empêchera cette personne de vous envoyer de nouveaux messages.',
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
    if (confirme != true || !mounted) return;
    _informer(
      'Le blocage sera activé dès que l’API de profil sera disponible.',
    );
  }

  Future<void> _supprimerConversation() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          _estGroupe ? 'Quitter le groupe ?' : 'Supprimer la conversation ?',
        ),
        content: Text(
          _estGroupe
              ? 'Vous ne recevrez plus les messages de ce groupe.'
              : 'Cette conversation sera retirée de votre liste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(_estGroupe ? 'Quitter' : 'Supprimer'),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;

    setState(() => _enCours = true);
    try {
      await ref
          .read(conversationRepositoryProvider)
          .quitterConversation(widget.conversation.id);
      ref
          .read(conversationListProvider.notifier)
          .retirerConversation(widget.conversation.id);
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        setState(() => _enCours = false);
        _informer('Impossible de réaliser cette action pour le moment.');
      }
    }
  }

  Future<void> _modifierNomGroupe() async {
    final controller = TextEditingController(text: _nomGroupe);
    final nouveauNom = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le nom du groupe'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nom du groupe'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nouveauNom == null || nouveauNom.isEmpty || !mounted) return;
    setState(() => _nomGroupe = nouveauNom);
    ref
        .read(conversationListProvider.notifier)
        .renommerConversation(widget.conversation.id, nouveauNom);
    _informer('Le nom du groupe a été modifié.');
  }

  Future<void> _modifierPhotoGroupe() async {
    final selection = await choisirImageDepuisGalerie();
    if (selection == null || !mounted) return;
    _informer('La photo du groupe a été sélectionnée.');
  }

  Future<void> _ouvrirAjoutParticipants() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddGroupParticipantsScreen(
          conversationId: widget.conversation.id,
          conversationNom: _nomGroupe,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nom = _estGroupe ? _nomGroupe : widget.conversation.nom;
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          const SizedBox(height: 12),
          AvatarCircle(
            initiales:
                widget.conversation.avatarInitiales ?? nom.substring(0, 1),
            size: 84,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              nom,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 6),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _Raccourci(
                  icon: Icons.call,
                  label: 'Appeler',
                  onTap: () =>
                      _informer('L’appel audio sera disponible prochainement.'),
                ),
                _Raccourci(
                  icon: Icons.videocam,
                  label: 'Discussion vidéo',
                  onTap: () =>
                      _informer('L’appel vidéo sera disponible prochainement.'),
                ),
                _Raccourci(
                  icon: _estGroupe
                      ? Icons.person_add_alt_1
                      : Icons.person_outline,
                  label: _estGroupe ? 'Ajouter' : 'Profil',
                  onTap: _estGroupe
                      ? _ouvrirAjoutParticipants
                      : () => _informer('Profil de $nom'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (_estGroupe) ..._optionsGroupe(nom) else ..._optionsPrivees(nom),
        ],
      ),
    );
  }

  List<Widget> _optionsGroupe(String nom) => [
    const _TitreSection('Actions'),
    _Option(
      icon: Icons.mark_email_unread_outlined,
      titre: 'Marquer comme non lu',
      onTap: () => _informer('La discussion est marquée comme non lue.'),
    ),
    _Option(
      icon: Icons.group_outlined,
      titre: 'Voir les participants',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationMembersScreen(conversationNom: nom),
        ),
      ),
    ),
    const _TitreSection('Personnalisation'),
    _Option(
      icon: Icons.edit_outlined,
      titre: 'Modifier le nom du groupe',
      onTap: _modifierNomGroupe,
    ),
    _Option(
      icon: Icons.photo_outlined,
      titre: 'Modifier la photo du groupe',
      onTap: _modifierPhotoGroupe,
    ),
    const _TitreSection('Sécurité et assistance'),
    _Option(
      icon: Icons.flag_outlined,
      titre: 'Signaler',
      danger: true,
      onTap: () => _informer('Conversation signalée à la modération.'),
    ),
    _Option(
      icon: _enCours ? Icons.hourglass_top : Icons.logout,
      titre: 'Quitter le groupe',
      danger: true,
      onTap: _enCours ? null : _supprimerConversation,
    ),
  ];

  List<Widget> _optionsPrivees(String nom) => [
    const _TitreSection('Actions'),
    _Option(
      icon: Icons.group_add_outlined,
      titre: 'Créer un groupe avec $nom',
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NewConversationScreen())),
    ),
    _Option(
      icon: Icons.photo_outlined,
      titre: 'Médias partagés',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SharedMediaScreen(conversationNom: nom),
        ),
      ),
    ),
    const _TitreSection('Sécurité et assistance'),
    _Option(
      icon: Icons.block_outlined,
      titre: 'Bloquer $nom',
      danger: true,
      onTap: _confirmerBlocage,
    ),
    _Option(
      icon: Icons.flag_outlined,
      titre: 'Signaler',
      danger: true,
      onTap: () => _informer('Conversation signalée à la modération.'),
    ),
    _Option(
      icon: _enCours ? Icons.hourglass_top : Icons.delete_outline,
      titre: 'Supprimer la conversation',
      danger: true,
      onTap: _enCours ? null : _supprimerConversation,
    ),
  ];
}

class _TitreSection extends StatelessWidget {
  const _TitreSection(this.titre);
  final String titre;
  @override
  Widget build(BuildContext context) => Padding(
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
  Widget build(BuildContext context) => SizedBox(
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
  Widget build(BuildContext context) => ListTile(
    dense: true,
    leading: CircleAvatar(
      radius: 18,
      backgroundColor: danger
          ? const Color(0xFFFFEBEE)
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
