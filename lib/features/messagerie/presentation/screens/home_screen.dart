import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/conversation_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/utils/message_date_formatter.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../../../shared/widgets/unread_badges.dart';
import '../../../bot/presentation/screens/bot_chat_screen.dart';
import '../../providers/conversation_providers.dart';
import 'conversation_list_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(conversationListProvider.notifier).rafraichir();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WelcomeHeader(),
              const SizedBox(height: 14),
              _AssistantPromo(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BotChatScreen()),
                ),
              ),
              const SizedBox(height: 18),
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
      2 => const ProfileScreen(),
      _ => null,
    };

    if (destination != null) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => destination));
    }
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bonjour, Étudiant',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Prêt pour une nouvelle journée\nd’apprentissage ?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _AssistantPromo extends StatelessWidget {
  const _AssistantPromo({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDCEFE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assistant AI',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E2E2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Comment puis-je vous aider aujourd’hui ?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ],
              ),
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
              'Derniers messages privés',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: onViewAll,
              child: const Text(
                'TOUT VOIR',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        conversationsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('Erreur : $error'),
          data: (conversations) {
            final recents = conversations
                .where(
                  (conversation) =>
                      conversation.type == ConversationType.privee,
                )
                .take(4)
                .toList();

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

  @override
  Widget build(BuildContext context) {
    final dernierMessage = conversation.dernierMessage;
    // Dans « Derniers messages privés », le nom correspond à l'auteur du
    // dernier message, et non systématiquement au contact de la conversation.
    final nomExpediteur = dernierMessage?.expediteurNom.trim();
    final nomAffiche = nomExpediteur == null || nomExpediteur.isEmpty
        ? conversation.nom
        : nomExpediteur;
    final initiales =
        conversation.avatarInitiales ??
        (nomAffiche.isNotEmpty ? nomAffiche[0] : '?');

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
          nomAffiche,
          style: TextStyle(
            color: conversation.nombreNonLus > 0
                ? AppColors.textPrimary
                : AppColors.textSecondary,
            fontSize: conversation.nombreNonLus > 0 ? 15 : 14,
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
            fontSize: conversation.nombreNonLus > 0 ? 14 : 13,
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
                    MessageDateFormatter.format(
                      conversation.dernierMessage!.dateEnvoi,
                    ),
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
