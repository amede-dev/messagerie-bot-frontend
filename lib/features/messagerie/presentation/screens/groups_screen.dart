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
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationListProvider);

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
              const _DiscoverGroup(
                title: 'Société de Débat',
                members: '89 membres',
                icon: Icons.forum_outlined,
              ),
              const _DiscoverGroup(
                title: 'Club Littéraire',
                members: '45 membres',
                icon: Icons.menu_book_outlined,
              ),
              const _DiscoverGroup(
                title: 'Mathématiques Avancées',
                members: '12 membres',
                icon: Icons.functions,
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => destination),
            );
          }
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Accueil'),
          NavigationDestination(
            icon: UnreadMessagesBadge(
              child: Image.asset('assets/images/messangeur.png', width: 24, height: 24),
            ),
            selectedIcon: UnreadMessagesBadge(
              child: Image.asset('assets/images/messangeur.png', width: 26, height: 26),
            ),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: UnreadNotificationsBadge(child: Icon(Icons.notifications_none)),
            label: 'Notifications',
          ),
          NavigationDestination(icon: Icon(Icons.group), label: 'Groupes'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
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
  });

  final String title;
  final String members;
  final IconData icon;

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
                  Text(members,
                      style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
