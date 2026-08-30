import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_model.dart';
import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../../../shared/widgets/messenger_nav_icon.dart';
import '../../../../shared/widgets/unread_badges.dart';
import '../../../../shared/widgets/uni_logo.dart';
import '../../../bot/presentation/screens/bot_chat_screen.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';
import 'contact_list_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

// Écran principal de la messagerie.

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  String _filtre = 'Toutes';

  // INITIALISATION

  @override
  void initState() {
    super.initState();
    // L'écran affiche désormais toutes les conversations
    _filtre = 'Toutes';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(conversationListProvider.notifier).rafraichir();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  // RECHERCHE

  Future<void> _ouvrirRecherche() async {
    late final List<AppUserModel> contacts;
    try {
      contacts = await ref.read(contactsUniversitairesProvider.future);
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les contacts : $erreur')),
      );
      return;
    }

    if (!mounted) return;

    final contact = await showDialog<AppUserModel>(
      context: context,
      builder: (dialogContext) {
        return _RechercheContactsDialog(
          contacts: contacts,
          onContactSelected: (selected) {
            Navigator.of(dialogContext).pop(selected);
          },
        );
      },
    );

    if (contact != null && mounted) {
      await _demarrerConversationAvec(contact);
    }
  }

  // UNI AI

  Future<void> _ouvrirUni() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BotChatScreen()));
  }

  // NOUVELLE CONVERSATION

  Future<void> _ouvrirNouvelleConversation() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ContactListScreen()));
  }

  // DÉMARRER UNE DISCUSSION AVEC UN CONTACT

  Future<void> _demarrerConversationAvec(AppUserModel contact) async {
    try {
      final conversation = await ref
          .read(conversationRepositoryProvider)
          .creerConversationPrivee(contact.id);

      // Rafraîchir la liste après création.
      await ref.read(conversationListProvider.notifier).rafraichir();

      if (!mounted) {
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ouvrir la discussion : $erreur')),
      );
    }
  }

  // ACTIONS SUR UNE CONVERSATION

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
      builder: (context) {
        return SafeArea(
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
                onTap: () {
                  Navigator.of(context).pop('supprimer');
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (action != 'supprimer' || !mounted) {
      return;
    }

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer la conversation ?'),
          content: Text(
            'La conversation avec « ${conversation.nom} » '
            'sera retirée de votre liste.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirme != true || !mounted) {
      return;
    }

    try {
      await ref
          .read(conversationRepositoryProvider)
          .quitterConversation(conversation.id);

      ref
          .read(conversationListProvider.notifier)
          .retirerConversation(conversation.id);
    } catch (erreur) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible de supprimer la conversation : $erreur'),
        ),
      );
    }
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationListProvider);
    final messagesNonLus = ref.watch(unreadMessagesCountProvider);
    final contactsAsync = ref.watch(contactsUniversitairesProvider);

    return Scaffold(
      // APP BAR
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,

        title: const Row(
          children: [
            ClipOval(
              child: Image(
                image: AssetImage('assets/images/logo_eni.jpeg'),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Messagerie',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            onPressed: _ouvrirRecherche,
            icon: const Icon(Icons.search_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),

      // BODY
      body: Column(
        children: [
          _ContactsRapides(
            contactsAsync: contactsAsync,
            onContactTap: _demarrerConversationAvec,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filtreConversation('Toutes'),
                const SizedBox(width: 8),
                _filtreConversation('Non lus', messagesNonLus),
              ],
            ),
          ),

          // LISTE DES CONVERSATIONS
          Expanded(
            child: conversationsAsync.when(
              // CHARGEMENT
              loading: () {
                return const Center(child: CircularProgressIndicator());
              },

              // ERREUR
              error: (err, _) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),

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
                            color: AppColors.textSecondary,
                          ),
                        ),

                        const SizedBox(height: 16),

                        FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(conversationListProvider.notifier)
                                .rafraichir();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                );
              },

              // DONNÉES
              data: (conversationsBrutes) {
                // FILTRAGE DES CONVERSATIONS

                final conversations = conversationsBrutes.where((conversation) {
                  final correspondFiltre =
                      _filtre == 'Toutes' || conversation.nombreNonLus > 0;
                  return correspondFiltre;
                }).toList();

                // AUCUN RÉSULTAT

                if (conversations.isEmpty) {
                  return const Center(
                    child: Text('Aucun contact ou message trouvé'),
                  );
                }

                // LISTE

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(conversationListProvider.notifier)
                        .rafraichir();
                  },

                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),

                    children: [
                      ...conversations.map((conversation) {
                        return Column(
                          children: [
                            ConversationTile(
                              conversation: conversation,

                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ChatScreen(conversation: conversation),
                                  ),
                                );
                              },

                              onLongPress: () {
                                _ouvrirActionsConversation(conversation);
                              },
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // BOUTONS FLOTTANTS
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BOUTON UNI AI
          Tooltip(
            message: 'Ouvrir Uni AI',
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _ouvrirUni,
                customBorder: const CircleBorder(),

                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: UniLogo(size: 48),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // BOUTON +
          FloatingActionButton(
            heroTag: 'new_conversation_button',
            onPressed: _ouvrirNouvelleConversation,
            backgroundColor: AppColors.primary,
            shape: const CircleBorder(),

            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: UnreadMessagesBadge(
              child: const MessengerNavIcon(selected: false),
            ),
            selectedIcon: UnreadMessagesBadge(
              child: const MessengerNavIcon(selected: true),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _filtreConversation(String filtre, [int compteur = 0]) {
    final actif = _filtre == filtre;
    return InkWell(
      onTap: () => setState(() => _filtre = filtre),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        constraints: const BoxConstraints(minWidth: 112),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: actif ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: actif ? AppColors.primary : AppColors.textMuted,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              filtre,
              style: TextStyle(
                color: actif ? Colors.white : AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (compteur > 0) ...[
              const SizedBox(width: 5),
              Text(
                '($compteur)',
                style: TextStyle(
                  color: actif ? Colors.white : AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// CONTACTS RAPIDES

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
      // CHARGEMENT
      loading: () {
        return const SizedBox(
          height: 98,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },

      // ERREUR
      error: (_, _) {
        return const SizedBox.shrink();
      },

      // DONNÉES
      data: (contacts) {
        if (contacts.isEmpty) {
          return const SizedBox.shrink();
        }

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

                  separatorBuilder: (_, _) => const SizedBox(width: 12),

                  itemBuilder: (context, index) {
                    final contact = contacts[index];

                    final prenom = contact.prenom.trim().isEmpty
                        ? contact.nomComplet
                        : contact.prenom.trim();

                    return SizedBox(
                      width: 58,

                      child: InkWell(
                        borderRadius: BorderRadius.circular(32),

                        onTap: () {
                          onContactTap(contact);
                        },

                        child: Column(
                          children: [
                            AvatarCircle(
                              initiales: contact.initiales,
                              size: 50,
                              imageUrl: contact.photoUrl,
                              estEnLigne: contact.enLigne,
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

// Recherche de contacts
class _RechercheContactsDialog extends StatefulWidget {
  const _RechercheContactsDialog({
    required this.contacts,
    required this.onContactSelected,
  });

  final List<AppUserModel> contacts;
  final ValueChanged<AppUserModel> onContactSelected;

  @override
  State<_RechercheContactsDialog> createState() =>
      _RechercheContactsDialogState();
}

class _RechercheContactsDialogState extends State<_RechercheContactsDialog> {
  final _controller = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final terme = _recherche.trim().toLowerCase();
    final contacts = widget.contacts.where((contact) {
      return terme.isEmpty || contact.nomComplet.toLowerCase().contains(terme);
    }).toList();

    return AlertDialog(
      title: const Text('Rechercher un contact'),
      content: SizedBox(
        width: double.maxFinite,
        height: 390,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _recherche = value),
              decoration: InputDecoration(
                hintText: 'Rechercher',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _recherche.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _recherche = '');
                        },
                      ),
                filled: true,
                fillColor: AppColors.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: contacts.isEmpty
                  ? const Center(child: Text('Aucun contact trouvé'))
                  : ListView.separated(
                      itemCount: contacts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (context, index) {
                        final contact = contacts[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: AvatarCircle(
                            initiales: contact.initiales,
                            imageUrl: contact.photoUrl,
                            estEnLigne: contact.enLigne,
                          ),
                          title: Text(contact.nomComplet),
                          onTap: () => widget.onContactSelected(contact),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
