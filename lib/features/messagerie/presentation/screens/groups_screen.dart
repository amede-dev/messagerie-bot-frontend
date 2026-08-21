import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';
import 'conversation_list_screen.dart';
import 'home_screen.dart';
import 'new_conversation_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../../../../shared/widgets/unread_badges.dart';

/// Groupes d'étude et clubs. Les groupes affichés viennent de la table
/// conversation via le provider déjà connecté au backend.
class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  final _rechercheController = TextEditingController();
  String _recherche = '';

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conversations = ref.watch(conversationListProvider);
    final groupesDisponibles = ref.watch(groupesDisponiblesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'UniSocial',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
      ),
      body: conversations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur : $error')),
        data: (items) {
          final groupes = items
              .where((item) => item.type == ConversationType.groupe)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              const Text(
                'Groupes d’étude & Clubs',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Trouvez votre communauté étudiante.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rechercheController,
                onChanged: (value) => setState(() => _recherche = value),
                decoration: const InputDecoration(
                  hintText: 'Rechercher un groupe...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Mes Groupes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              if (groupes.isEmpty)
                const _EmptyGroups()
              else
                ...groupes.map(
                  (groupe) => ConversationTile(
                    conversation: groupe,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(conversation: groupe),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Découvrir',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              groupesDisponibles.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, _) => Text('Erreur : $error'),
                data: (groupes) {
                  final recherche = _recherche.trim().toLowerCase();
                  final groupesFiltres = recherche.isEmpty
                      ? groupes
                      : groupes
                            .where((groupe) => groupe.nom.toLowerCase().contains(recherche))
                            .toList();

                  return groupesFiltres.isEmpty
                    ? const Text(
                        'Aucun groupe public disponible pour le moment.',
                        style: TextStyle(color: AppColors.textSecondary),
                      )
                    : Column(
                        children: groupesFiltres.map((groupe) {
                          return _DiscoverGroup(
                            title: groupe.nom,
                            members: '${groupe.nombreMembres} membres',
                            icon: Icons.groups_outlined,
                            onJoin: () async {
                              try {
                                final conversation = await ref
                                    .read(conversationRepositoryProvider)
                                    .rejoindreGroupe(groupe.id);
                                ref.invalidate(groupesDisponiblesProvider);
                                await ref
                                    .read(conversationListProvider.notifier)
                                    .rafraichir();
                                if (!context.mounted) return;
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatScreen(
                                      conversation: conversation,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Impossible de rejoindre le groupe : $e',
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      );
                },
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NewConversationScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: (index) {
          final destination = switch (index) {
            0 => const HomeScreen(),
            1 => const ConversationListScreen(),
            2 => const NotificationsScreen(),
            4 => const ProfileScreen(),
            _ => null,
          };

          if (destination != null) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => destination));
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
          NavigationDestination(icon: Icon(Icons.group), label: 'Groupes'),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text('Vous n’avez encore rejoint aucun groupe.'),
      ),
    );
  }
}

class _DiscoverGroup extends StatelessWidget {
  const _DiscoverGroup({
    required this.title,
    required this.members,
    required this.icon,
    required this.onJoin,
  });

  final String title;
  final String members;
  final IconData icon;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primaryLight,
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    members,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onJoin,
              child: const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
