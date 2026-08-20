import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../../../shared/widgets/unread_badges.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../bot/presentation/screens/bot_chat_screen.dart';
import '../../providers/conversation_providers.dart';
import 'conversation_list_screen.dart';
import 'contact_list_screen.dart';
import 'groups_screen.dart';
import 'new_conversation_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            Expanded(
              child: Text(
                'Réseau Social Universitaire ENI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 8),
            ClipOval(
              child: Image(
                image: AssetImage('assets/images/logo_eni.jpeg'),
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Accès rapide — tous les écrans',
            icon: const Icon(Icons.apps),
            onSelected: (value) => _ouvrirEcran(context, value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'connexion', child: Text('Connexion')),
              PopupMenuItem(value: 'privees', child: Text('Messages privés')),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AssistantPromo(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BotChatScreen()),
                ),
              ),
              const SizedBox(height: 24),
              _QuickAccess(
                onConversationTap: () =>
                    _ouvrirMenuNouvelleConversation(context),
              ),
              const SizedBox(height: 24),
              _RecentMessages(
                onViewAll: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConversationListScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          _ouvrirNavigation(context, index);
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
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

  static void _ouvrirNavigation(BuildContext context, int index) {
    final destination = switch (index) {
      1 => const ConversationListScreen(),
      2 => const NotificationsScreen(),
      3 => const GroupsScreen(),
      4 => const ProfileScreen(),
      _ => null,
    };

    if (destination != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => destination));
    }
  }

  static Future<void> _ouvrirMenuNouvelleConversation(
    BuildContext context,
  ) async {
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
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

    if (!context.mounted || choix == null) return;

    final destination = choix == 'privee'
        ? const ContactListScreen()
        : const NewConversationScreen();

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => destination));
  }

  static void _ouvrirEcran(BuildContext context, String value) {
    final destination = switch (value) {
      'connexion' => const LoginScreen(),
      'accueil' => const HomeScreen(),
      'messagerie' => const ConversationListScreen(),
      'chat' => const ConversationListScreen(),
      'notifications' => const NotificationsScreen(),
      'nouvelle' => const NewConversationScreen(),
      'privees' => const ConversationListScreen(),
      'groupes' => const GroupsScreen(),
      'profil' => const ProfileScreen(),
      'assistant' => const BotChatScreen(),
      _ => null,
    };

    if (destination != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => destination));
    }
  }
}

class _AssistantPromo extends StatelessWidget {
  const _AssistantPromo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E2E2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.smart_toy, color: Colors.white),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Besoin d’aide pour vos cours ?',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Demandez à UniBot, votre assistant académique 24/7.',
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              child: const Text('Démarrer'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccess extends StatelessWidget {
  const _QuickAccess({required this.onConversationTap});

  final VoidCallback onConversationTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Accès Rapide',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            _QuickAccessCard(
              icon: Icons.add_comment_outlined,
              title: 'Nouvelle Conversation',
              subtitle: "Rechercher dans l'annuaire",
              onTap: onConversationTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        // Hauteur bornée indispensable ici : la carte est dans un
        // SingleChildScrollView et contient un Spacer.
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E2E2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 20,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(icon, color: AppColors.primary),
                ),
                if (status != null)
                  Flexible(
                    child: Text(
                      status!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentMessages extends ConsumerWidget {
  const _RecentMessages({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationListProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Messages Récents',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            TextButton(onPressed: onViewAll, child: const Text('Voir tout')),
          ],
        ),
        conversationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Erreur : $error'),
          data: (conversations) {
            final recents = conversations.take(3).toList();

            if (recents.isEmpty) {
              return const Text('Aucun message récent.');
            }

            return Column(
              children: recents
                  .map(
                    (conversation) => _RecentMessageCard(
                      conversation: conversation,
                      onTap: onViewAll,
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _RecentMessageCard extends StatelessWidget {
  const _RecentMessageCard({required this.conversation, required this.onTap});

  final ConversationModel conversation;
  final VoidCallback onTap;

  String _dateAffichee(DateTime date) {
    final maintenant = DateTime.now();
    final aujourdHui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final jourMessage = DateTime(date.year, date.month, date.day);
    final difference = aujourdHui.difference(jourMessage).inDays;
    final heure = DateFormat('HH:mm').format(date);
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    if (difference == 0) return heure;
    if (difference == 1) return 'Hier $heure';
    if (difference < 7) {
      return '${jours[date.weekday - 1]} $heure';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final initiales =
        conversation.avatarInitiales ??
        (conversation.nom.isNotEmpty ? conversation.nom[0] : '?');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE2E2E2)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: AvatarCircle(
          initiales: initiales,
          size: 46,
          estEnLigne: conversation.estEnLigne,
          imageUrl: conversation.photoUrl,
        ),
        title: Text(
          conversation.nom,
          style: TextStyle(
            color: conversation.nombreNonLus > 0
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: conversation.nombreNonLus > 0
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          conversation.dernierMessage?.contenu ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversation.nombreNonLus > 0
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontWeight: conversation.nombreNonLus > 0
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
        trailing: conversation.dernierMessage == null
            ? null
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _dateAffichee(conversation.dernierMessage!.dateEnvoi),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  if (conversation.nombreNonLus > 0) ...[
                    const SizedBox(height: 5),
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        '${conversation.nombreNonLus}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
