import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/network/auth_repository.dart';
import '../../../../core/models/app_user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../../../shared/widgets/uni_logo.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../bot/presentation/screens/bot_chat_screen.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';
import 'contact_list_screen.dart';
import 'new_conversation_screen.dart';

// Écran d'accueil du module Messagerie, calqué sur la disposition de
// Messenger : "Messages" à gauche, logo Uni + recherche + paramètres à
// droite, bouton flottant "+" pour démarrer une discussion ou un groupe.
class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  final _rechercheController = TextEditingController();
  final _authRepository = AuthRepository();
  final _stockage = const FlutterSecureStorage();
  String _recherche = '';
  bool _rechercheOuverte = false;
  bool _uniAiMasque = false;

  static const _cleUniAiMasque = 'uni_ai_masque';

  @override
  void initState() {
    super.initState();
    _chargerEtatUniAi();
  }

  Future<void> _chargerEtatUniAi() async {
    final estMasque = await _stockage.read(key: _cleUniAiMasque) == 'true';
    if (!mounted) return;
    setState(() => _uniAiMasque = estMasque);
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  void _basculerRecherche() {
    setState(() {
      _rechercheOuverte = !_rechercheOuverte;
      if (!_rechercheOuverte) {
        _rechercheController.clear();
        _recherche = '';
      }
    });
  }

  Future<void> _ouvrirUni() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BotChatScreen()));
  }

  Future<void> _restaurerEtOuvrirUni() async {
    if (_uniAiMasque) {
      await _stockage.delete(key: _cleUniAiMasque);
      if (!mounted) return;
      setState(() => _uniAiMasque = false);
    }
    if (!mounted) return;
    await _ouvrirUni();
  }

  Future<void> _ouvrirActionsUniAi() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline, color: AppColors.danger),
          title: const Text(
            'Supprimer la conversation',
            style: TextStyle(color: AppColors.danger),
          ),
          onTap: () => Navigator.of(context).pop('supprimer'),
        ),
      ),
    );

    if (action != 'supprimer' || !mounted) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation Uni AI ?'),
        content: const Text(
          'Uni AI sera retiré de votre liste. Vous pourrez le retrouver en appuyant sur son icône flottante.',
        ),
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

    if (confirme != true || !mounted) return;
    await _stockage.write(key: _cleUniAiMasque, value: 'true');
    if (!mounted) return;
    setState(() => _uniAiMasque = true);
  }

  Future<void> _demarrerConversationAvec(AppUserModel contact) async {
    try {
      final conversation = await ref
          .read(conversationRepositoryProvider)
          .creerConversationPrivee(contact.id);
      await ref.read(conversationListProvider.notifier).rafraichir();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir la discussion : $erreur')),
      );
    }
  }

  Future<void> _ouvrirActionsConversation(
    ConversationModel conversation,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
              ),
              title: const Text(
                'Supprimer la conversation',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () => Navigator.of(context).pop('supprimer'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action != 'supprimer' || !mounted) return;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la conversation ?'),
        content: Text(
          'La conversation avec « ${conversation.nom} » sera retirée de votre liste.',
        ),
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

    if (confirme != true || !mounted) return;
    try {
      await ref
          .read(conversationRepositoryProvider)
          .quitterConversation(conversation.id);
      ref
          .read(conversationListProvider.notifier)
          .retirerConversation(conversation.id);
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de supprimer la conversation : $erreur'),
        ),
      );
    }
  }

  Future<void> _seDeconnecter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tu devras te reconnecter pour accéder à tes conversations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    await _authRepository.deconnexion();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Menu "paramètres" ouvert via l'icône ⚙ en haut à droite.
  Future<void> _ouvrirParametres() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Paramètres',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _seDeconnecter();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Choix "Nouvelle discussion" (1 à 1) ou "Nouveau groupe", accessible
  /// via le bouton flottant "+", à l'instar des applications de
  /// messagerie classiques.
  Future<void> _ouvrirMenuNouvelleConversation() async {
    final choix = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusL),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Nouveau',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Nouvelle discussion'),
              subtitle: const Text('Choisir un contact dans l\'annuaire'),
              onTap: () => Navigator.of(context).pop('privee'),
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined),
              title: const Text('Nouveau groupe'),
              subtitle: const Text('Plusieurs participants à la fois'),
              onTap: () => Navigator.of(context).pop('groupe'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choix == null || !mounted) return;
    if (choix == 'privee') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ContactListScreen()));
    } else {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NewConversationScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationListProvider);
    final contactsAsync = ref.watch(contactsUniversitairesProvider);
    const nomBot = 'Uni AI';
    final botCorrespond = nomBot.toLowerCase().contains(
      _recherche.toLowerCase(),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Text(
          'Messages',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(_rechercheOuverte ? Icons.close : Icons.search),
            tooltip: 'Rechercher',
            onPressed: _basculerRecherche,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Paramètres',
            onPressed: _ouvrirParametres,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (_rechercheOuverte)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _rechercheController,
                autofocus: true,
                onChanged: (val) => setState(() => _recherche = val),
                decoration: InputDecoration(
                  hintText: 'Rechercher',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          _ContactsRapides(
            contactsAsync: contactsAsync,
            onContactTap: _demarrerConversationAvec,
          ),
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les conversations.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$err',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(conversationListProvider.notifier)
                            .rafraichir(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (conversationsBrutes) {
                final conversations = _recherche.isEmpty
                    ? conversationsBrutes
                    : conversationsBrutes
                          .where(
                            (c) => c.nom.toLowerCase().contains(
                              _recherche.toLowerCase(),
                            ),
                          )
                          .toList();

                final contacts =
                    contactsAsync.valueOrNull ?? const <AppUserModel>[];
                final contactsFiltres = _recherche.isEmpty
                    ? contacts
                    : contacts
                          .where(
                            (contact) => contact.nomComplet
                                .toLowerCase()
                                .contains(_recherche.toLowerCase()),
                          )
                          .toList();

                if (conversations.isEmpty &&
                    contactsFiltres.isEmpty &&
                    (!botCorrespond || _uniAiMasque)) {
                  return const Center(
                    child: Text('Aucun contact ou message trouvé'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(contactsUniversitairesProvider);
                    await ref
                        .read(conversationListProvider.notifier)
                        .rafraichir();
                  },
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      if (botCorrespond && !_uniAiMasque) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: const UniLogo(size: 42),
                          title: const Text(
                            nomBot,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text(
                            'Assistant intelligent · toujours disponible',
                          ),
                          onTap: _ouvrirUni,
                          onLongPress: _ouvrirActionsUniAi,
                        ),
                      ],
                      ...conversations.map(
                        (conversation) => Column(
                          children: [
                            ConversationTile(
                              conversation: conversation,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ChatScreen(conversation: conversation),
                                ),
                              ),
                              onLongPress: () =>
                                  _ouvrirActionsConversation(conversation),
                            ),
                          ],
                        ),
                      ),
                      if (contactsFiltres.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
                          child: Text(
                            'Tous les contacts',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        ...contactsFiltres.map(
                          (contact) => Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                leading: AvatarCircle(
                                  initiales: contact.initiales,
                                ),
                                title: Text(
                                  contact.nomComplet,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () => _demarrerConversationAvec(contact),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      // L'assistant Uni AI est placé juste au-dessus du bouton de création,
      // comme les assistants des applications de messagerie modernes.
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Ouvrir Uni AI',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _restaurerEtOuvrirUni,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: UniLogo(size: 48),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            onPressed: _ouvrirMenuNouvelleConversation,
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

class _ContactsRapides extends StatelessWidget {
  const _ContactsRapides({
    required this.contactsAsync,
    required this.onContactTap,
  });

  final AsyncValue<List<AppUserModel>> contactsAsync;
  final ValueChanged<AppUserModel> onContactTap;

  @override
  Widget build(BuildContext context) {
    return contactsAsync.when(
      loading: () => const SizedBox(
        height: 98,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (contacts) {
        if (contacts.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 108,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 6),
                child: Text(
                  'Contacts',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: contacts.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final prenom = contact.prenom.trim().isEmpty
                        ? contact.nomComplet
                        : contact.prenom.trim();
                    return SizedBox(
                      width: 58,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),
                        onTap: () => onContactTap(contact),
                        child: Column(
                          children: [
                            AvatarCircle(
                              initiales: contact.initiales,
                              size: 50,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prenom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }
}
