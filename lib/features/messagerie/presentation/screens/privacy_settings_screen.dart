import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profilVisible = true;
  bool _presenceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confidentialité')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Paramètres de confidentialité',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contrôlez la visibilité de votre profil et de votre présence.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  title: const Text('Profil visible dans l’annuaire'),
                  subtitle: const Text(
                    'Les autres utilisateurs peuvent vous trouver.',
                  ),
                  value: _profilVisible,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => _profilVisible = value),
                ),
                SwitchListTile.adaptive(
                  title: const Text('Afficher ma présence en ligne'),
                  subtitle: const Text(
                    'Les contacts voient si vous êtes connecté.',
                  ),
                  value: _presenceVisible,
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      setState(() => _presenceVisible = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ces réglages sont actuellement appliqués localement sur cet appareil.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
