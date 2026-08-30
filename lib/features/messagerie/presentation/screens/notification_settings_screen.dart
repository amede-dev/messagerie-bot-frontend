import 'package:flutter/material.dart';

import '../../../../core/network/api_client.dart';
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

  Future<void> _supprimerToutesLesNotifications() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer les notifications ?'),
        content: const Text(
          'Toutes vos notifications seront supprimées de la base de données.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmer != true || !mounted) return;

    try {
      await ApiClient.instance.supprimerToutesLesNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications supprimées.')),
      );
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Suppression impossible : $erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _supprimerToutesLesNotifications,
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Supprimer toutes les notifications',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gérez les notifications de votre réseau universitaire.',
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
            'Utilisez l’icône de suppression en haut pour effacer vos notifications enregistrées.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
