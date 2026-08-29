import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/notification_model.dart';
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
  late Future<List<NotificationModel>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _notificationsFuture = _chargerNotifications();
  }

  Future<List<NotificationModel>> _chargerNotifications() async {
    final response = await ApiClient.instance.getNotifications();
    final donnees = response.data as List<dynamic>;
    return donnees
        .map(
          (donnee) =>
              NotificationModel.fromJson(donnee as Map<String, dynamic>),
        )
        .toList();
  }

  void _actualiser() {
    setState(() => _notificationsFuture = _chargerNotifications());
  }

  Future<void> _rafraichir() async {
    final future = _chargerNotifications();
    setState(() => _notificationsFuture = future);
    await future;
  }

  Future<void> _supprimerNotification(NotificationModel notification) async {
    await ApiClient.instance.supprimerNotification(notification.id);
    if (mounted) _actualiser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const Text(
              'Notifications reçues',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<NotificationModel>>(
              future: _notificationsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snapshot.hasError) {
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: const Text('Notifications indisponibles'),
                      subtitle: Text('${snapshot.error}'),
                      trailing: IconButton(
                        onPressed: _actualiser,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  );
                }

                final notifications = snapshot.data ?? const [];
                if (notifications.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Aucune notification enregistrée pour le moment.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: notifications
                      .map(
                        (notification) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(
                                notification.type == 'MESSAGE'
                                    ? Icons.message_outlined
                                    : Icons.notifications_none,
                                color: AppColors.primary,
                              ),
                            ),
                            title: Text(
                              notification.type == 'MESSAGE'
                                  ? 'Nouveau message'
                                  : notification.type,
                              style: TextStyle(
                                fontWeight: notification.lue
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(notification.contenu),
                            isThreeLine: true,
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat(
                                    'dd/MM HH:mm',
                                  ).format(notification.dateCreation),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _supprimerNotification(notification),
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 19,
                                  ),
                                  tooltip: 'Supprimer',
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 20),
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
                onChanged: (value) =>
                    setState(() => _notificationsActivees = value),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Ce réglage est actuellement conservé localement sur cet appareil.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
