import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _notificationsActivees = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres des notifications')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez si vous souhaitez recevoir les notifications de votre réseau universitaire.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Activer les notifications'),
              subtitle: Text(
                _notificationsActivees
                    ? 'Les nouvelles notifications sont autorisées.'
                    : 'Les notifications sont désactivées.',
              ),
              value: _notificationsActivees,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(
                () => _notificationsActivees = value,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ce réglage est actuellement conservé localement sur cet appareil.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
