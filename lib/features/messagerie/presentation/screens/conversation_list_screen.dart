import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_model.dart';
import '../../../../core/models/conversation_model.dart';
import '../../../../core/network/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../../../shared/widgets/unread_badges.dart';
import '../../../../shared/widgets/uni_logo.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../bot/presentation/screens/bot_chat_screen.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';
import 'contact_list_screen.dart';
import 'groups_screen.dart';
import 'new_conversation_screen.dart';
import 'notifications_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

/// Écran principal de la messagerie.
///
/// Uni AI n'est pas affiché dans la liste des conversations.
/// Il est accessible uniquement par son bouton flottant,
/// placé juste au-dessus du bouton "+".
class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key, this.initialFilter = 'Toutes'});

  final String initialFilter;

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  final _rechercheController = TextEditingController();
  final _authRepository = AuthRepository();

  String _recherche = '';
  String _filtre = 'Toutes';

  // ===========================================================================
  // INITIALISATION
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _filtre = widget.initialFilter;
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // RECHERCHE
  // ===========================================================================

  // ===========================================================================
  // UNI AI
  // ===========================================================================

  /// Ouvre directement la conversation avec Uni AI.
  ///
  /// Uni AI n'est PAS ajouté à la liste des conversations.
  Future<void> _ouvrirUni() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BotChatScreen()));
  }

  // ===========================================================================
  // MENU DU BOUTON +
  // ===========================================================================

  /// Le bouton "+" permet uniquement de créer :
  ///
  /// - une nouvelle discussion privée
  /// - un nouveau groupe
  ///
  /// Uni AI est volontairement absent de ce menu.
  Future<void> _ouvrirMenuNouvelleConversation() async {
    final choix = await showModalBottomSheet<String>(
      context: context,
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
              // ---------------------------------------------------------------
              // TITRE
              // ---------------------------------------------------------------
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Nouveau',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                ),
              ),

              // ---------------------------------------------------------------
              // NOUVELLE DISCUSSION PRIVÉE
              // ---------------------------------------------------------------
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Nouvelle discussion'),
                subtitle: const Text('Choisir un contact dans l\'annuaire'),
                onTap: () {
                  Navigator.of(context).pop('privee');
                },
              ),

              // ---------------------------------------------------------------
              // NOUVEAU GROUPE
              // ---------------------------------------------------------------
              ListTile(
                leading: const Icon(Icons.group_outlined),
                title: const Text('Nouveau groupe'),
                subtitle: const Text('Plusieurs participants à la fois'),
                onTap: () {
                  Navigator.of(context).pop('groupe');
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (choix == null || !mounted) {
      return;
    }

    // -------------------------------------------------------------------------
    // NOUVELLE DISCUSSION PRIVÉE
    // -------------------------------------------------------------------------

    if (choix == 'privee') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ContactListScreen()));

      return;
    }

    // -------------------------------------------------------------------------
    // NOUVEAU GROUPE
    // -------------------------------------------------------------------------

    if (choix == 'groupe') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const NewConversationScreen()));
    }
  }

  // ===========================================================================
  // DÉMARRER UNE DISCUSSION AVEC UN CONTACT
  // ===========================================================================

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

  // ===========================================================================
  // ACTIONS SUR UNE CONVERSATION
  // ===========================================================================

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

  // ===========================================================================
  // DÉCONNEXION
  // ===========================================================================

  Future<void> _seDeconnecter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Se déconnecter ?'),
          content: const Text(
            'Tu devras te reconnecter pour accéder à tes conversations.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text(
                'Se déconnecter',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
          ],
        );
      },
    );

    if (confirme != true || !mounted) {
      return;
    }

    await _authRepository.deconnexion();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return Scaffold(
      // ========================================================================
      // APP BAR
      // ========================================================================
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,

        title: const Text(
          'Messagerie',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),

      // ========================================================================
      // BODY
      // ========================================================================
      body: Column(
        children: [
          // ---------------------------------------------------------------------
          // BARRE DE RECHERCHE
          // ---------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: TextField(
              controller: _rechercheController,
              onChanged: (val) => setState(() => _recherche = val),
              style: const TextStyle(color: Colors.black, fontSize: 14),
              cursorColor: AppColors.primary,
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                hintStyle: const TextStyle(color: Colors.black54, fontSize: 14),
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: ['Toutes', 'Privées', 'Groupes']
                  .map(
                    (filtre) => Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _filtre = filtre),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: _filtre == filtre
                                ? AppColors.primary
                                : Colors.black,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            filtre,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: _filtre == filtre
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // ---------------------------------------------------------------------
          // LISTE DES CONVERSATIONS
          // ---------------------------------------------------------------------
          Expanded(
            child: conversationsAsync.when(
              // =================================================================
              // CHARGEMENT
              // =================================================================
              loading: () {
                return const Center(child: CircularProgressIndicator());
              },

              // =================================================================
              // ERREUR
              // =================================================================
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

              // =================================================================
              // DONNÉES
              // =================================================================
              data: (conversationsBrutes) {
                // -----------------------------------------------------------------
                // FILTRAGE DES CONVERSATIONS
                // -----------------------------------------------------------------

                final conversations = conversationsBrutes.where((conversation) {
                  final correspondRecherche =
                      _recherche.isEmpty ||
                      conversation.nom.toLowerCase().contains(
                        _recherche.toLowerCase(),
                      );
                  final correspondFiltre = switch (_filtre) {
                    'Privées' => conversation.type == ConversationType.privee,
                    'Groupes' => conversation.type == ConversationType.groupe,
                    _ => true,
                  };
                  return correspondRecherche && correspondFiltre;
                }).toList();

                // -----------------------------------------------------------------
                // AUCUN RÉSULTAT
                // -----------------------------------------------------------------

                if (conversations.isEmpty) {
                  return const Center(
                    child: Text('Aucun contact ou message trouvé'),
                  );
                }

                // -----------------------------------------------------------------
                // LISTE
                // -----------------------------------------------------------------

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

      // ========================================================================
      // BOUTONS FLOTTANTS
      // ========================================================================
      //
      //                    ✨
      //                 Uni AI
      //                    │
      //                    ↓
      //                   (+)
      //
      // Uni AI est complètement séparé du bouton "+".
      // ========================================================================
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ====================================================================
          // BOUTON UNI AI
          // ====================================================================
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

          // ====================================================================
          // BOUTON +
          // ====================================================================
          FloatingActionButton(
            heroTag: 'new_conversation_button',
            onPressed: _ouvrirMenuNouvelleConversation,
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          } else if (index == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GroupsScreen()));
          } else if (index == 4) {
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
              child: Image.asset(
                'assets/images/messangeur.png',
                width: 24,
                height: 24,
              ),
            ),
            selectedIcon: UnreadMessagesBadge(
              child: Image.asset(
                'assets/images/messangeur.png',
                width: 26,
                height: 26,
              ),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: UnreadNotificationsBadge(
              child: Icon(Icons.notifications_none),
            ),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Groupes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// CONTACTS RAPIDES
// =============================================================================

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
      // -------------------------------------------------------------------------
      // CHARGEMENT
      // -------------------------------------------------------------------------
      loading: () {
        return const SizedBox(
          height: 98,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },

      // -------------------------------------------------------------------------
      // ERREUR
      // -------------------------------------------------------------------------
      error: (_, __) {
        return const SizedBox.shrink();
      },

      // -------------------------------------------------------------------------
      // DONNÉES
      // -------------------------------------------------------------------------
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

                        onTap: () {
                          onContactTap(contact);
                        },

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
