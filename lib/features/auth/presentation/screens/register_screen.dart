import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../messagerie/presentation/screens/conversation_list_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  final _confirmationController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _chargement = false;
  bool _motDePasseVisible = false;
  String? _erreur;

  @override
  void dispose() {
    for (final controller in [
      _nomController,
      _prenomController,
      _emailController,
      _motDePasseController,
      _confirmationController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await _authRepository.inscrire(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        motDePasse: _motDePasseController.text,
      );
      await WebSocketService.instance.connect();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ConversationListScreen()),
        (_) => false,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(
        () => _erreur = data is Map && data['message'] is String
            ? data['message'] as String
            : 'La création du compte a échoué. Vérifiez vos informations.',
      );
    } catch (_) {
      setState(
        () => _erreur = 'La création du compte a échoué. Réessayez plus tard.',
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  String? _requis(String? valeur) =>
      valeur == null || valeur.trim().isEmpty ? 'Ce champ est requis.' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Créer un compte')),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Rejoignez votre réseau universitaire',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vos informations permettent de créer votre profil étudiant.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _prenomController,
                    style: styleTexteSaisi,
                    cursorColor: AppColors.primary,
                    textCapitalization: TextCapitalization.words,
                    decoration: decorationChamp('Prénom', Icons.person_outline),
                    validator: _requis,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nomController,
                    style: styleTexteSaisi,
                    cursorColor: AppColors.primary,
                    textCapitalization: TextCapitalization.words,
                    decoration: decorationChamp('Nom', Icons.badge_outlined),
                    validator: _requis,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    style: styleTexteSaisi,
                    cursorColor: AppColors.primary,
                    keyboardType: TextInputType.emailAddress,
                    decoration: decorationChamp(
                      'Adresse e-mail',
                      Icons.alternate_email_outlined,
                    ),
                    validator: (v) => v == null || !v.contains('@')
                        ? 'Saisissez une adresse e-mail valide.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _motDePasseController,
                    style: styleTexteSaisi,
                    cursorColor: AppColors.primary,
                    obscureText: !_motDePasseVisible,
                    decoration:
                        decorationChamp(
                          'Mot de passe',
                          Icons.lock_outline,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _motDePasseVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () => setState(
                              () => _motDePasseVisible = !_motDePasseVisible,
                            ),
                          ),
                        ),
                    validator: (v) => v == null || v.length < 6
                        ? 'Le mot de passe doit contenir au moins 6 caractères.'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmationController,
                    style: styleTexteSaisi,
                    cursorColor: AppColors.primary,
                    obscureText: !_motDePasseVisible,
                    decoration: decorationChamp(
                      'Confirmer le mot de passe',
                      Icons.lock_reset_outlined,
                    ),
                    validator: (v) => v != _motDePasseController.text
                        ? 'Les mots de passe ne correspondent pas.'
                        : null,
                  ),
                  if (_erreur != null) ...[
                    const SizedBox(height: 16),
                    BanniereErreur(message: _erreur!),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _chargement ? null : _creerCompte,
                      child: _chargement
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Créer mon compte'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('J’ai déjà un compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
