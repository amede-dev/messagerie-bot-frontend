import 'package:flutter/material.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'conversation_list_screen.dart';
import 'groups_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _deconnecter(BuildContext context) async {
    await AuthRepository().deconnexion();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 14),
          const Text(
            'Mon profil universitaire',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Text(
                  'M1 Design Interactif',
                  style: TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const [
                  _ProfileStat(value: '142', label: 'Amis'),
                  _ProfileDivider(),
                  _ProfileStat(value: '8', label: 'Groupes'),
                  _ProfileDivider(),
                  _ProfileStat(value: '34', label: 'Posts'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'PARAMÈTRES',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _ProfileAction(
                  icon: Icons.person_outline,
                  label: 'Modifier le profil',
                ),
                _ProfileAction(
                  icon: Icons.lock_outline,
                  label: 'Paramètres de confidentialité',
                ),
                _ProfileAction(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _deconnecter(context),
            icon: const Icon(Icons.logout, color: AppColors.danger),
            label: const Text(
              'Déconnexion',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 3,
        onDestinationSelected: (index) {
          if (index == 0) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HomeScreen()));
          } else if (index == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ConversationListScreen()),
            );
          } else if (index == 2) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GroupsScreen()));
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            label: 'Groupes',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    ],
  );
}

class _ProfileDivider extends StatelessWidget {
  const _ProfileDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: const Color(0xFFC4C7C8));
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.textSecondary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
  );
}
