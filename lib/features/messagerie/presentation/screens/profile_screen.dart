import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/models/user_profile_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/network/auth_repository.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/file_upload_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/unread_badges.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'groups_screen.dart';
import 'home_screen.dart';
import 'conversation_list_screen.dart';
import 'notifications_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _photoProfil;
  String? _photoUrl;
  bool _envoiPhotoEnCours = false;
  late final Future<UserProfileModel> _profil = _chargerProfil();

  String? _normaliserPhotoUrl(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) return null;

    final url = valeur.trim();
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    // Une URL localhost enregistrée depuis un test local n'est pas accessible
    // depuis le téléphone. On conserve son chemin et on le relie au backend.
    if (uri.host == 'localhost' || uri.host == '127.0.0.1' || !uri.hasScheme) {
      return '${AppConfig.apiBaseUrl}${uri.path}';
    }

    return url;
  }

  Future<UserProfileModel> _chargerProfil() async {
    final response = await ApiClient.instance.getMonProfil();
    return UserProfileModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> _choisirPhotoProfil() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (!mounted || image == null) return;

    final fichier = File(image.path);
    setState(() => _envoiPhotoEnCours = true);

    try {
      final fichierEnvoye = await FileUploadService.instance.uploadPhotoProfil(
        fichier,
      );
      if (!mounted) return;
      setState(() {
        _photoProfil = fichier;
        _photoUrl = fichierEnvoye.url;
        _envoiPhotoEnCours = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo de profil enregistrée.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiPhotoEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’enregistrer la photo.')),
      );
    }
  }

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
      body: FutureBuilder<UserProfileModel>(
        future: _profil,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur : ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profil = snapshot.data!;
          final photoUrl = _normaliserPhotoUrl(_photoUrl ?? profil.photoUrl);
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            children: [
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primaryLight,
                      backgroundImage: _photoProfil == null
                          ? null
                          : FileImage(_photoProfil!),
                      child: _photoProfil == null
                          ? (photoUrl == null
                                ? const Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                    size: 52,
                                  )
                                : ClipOval(
                                    child: Image.network(
                                      photoUrl,
                                      width: 104,
                                      height: 104,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 52,
                                      ),
                                    ),
                                  ))
                          : null,
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          onTap: _choisirPhotoProfil,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_envoiPhotoEnCours)
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                profil.nomComplet.isEmpty
                    ? 'Profil universitaire'
                    : profil.nomComplet,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
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
                      icon: Icons.lock_outline,
                      label: 'Paramètres de confidentialité',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      ),
                    ),
                    _ProfileAction(
                      icon: Icons.notifications_none,
                      label: 'Notifications',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      ),
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
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 4,
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
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
            );
          } else if (index == 3) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GroupsScreen()));
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
          NavigationDestination(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.label, this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    leading: Icon(icon, color: AppColors.textSecondary),
    title: Text(
      label,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
    ),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
  );
}
