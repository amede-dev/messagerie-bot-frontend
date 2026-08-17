import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../messagerie/presentation/screens/conversation_list_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authRepository = AuthRepository();
  final _emailController = TextEditingController();
  final _motDePasseController = TextEditingController();
  bool _chargement = false;
  bool _motDePasseVisible = false;
  String? _erreur;

  @override
  void dispose() {
    _emailController.dispose();
    _motDePasseController.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      await _authRepository.login(
        _emailController.text.trim(),
        _motDePasseController.text,
      );
      await WebSocketService.instance.connect();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConversationListScreen()),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      setState(
        () => _erreur = data is Map && data['erreur'] is String
            ? data['erreur'] as String
            : 'Email ou mot de passe incorrect.',
      );
    } catch (_) {
      setState(
        () => _erreur = 'Impossible de se connecter. Réessayez plus tard.',
      );
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  void _ouvrirRecuperation() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) => const _RecuperationMotDePasseSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F0FB), AppColors.bgLight],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _EnteteAuthentification(),
                          const SizedBox(height: 32),
                          Text(
                            'Connexion',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Saisissez vos identifiants pour accéder à vos conversations.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: decorationChamp(
                              'Adresse e-mail',
                              Icons.alternate_email_outlined,
                            ),
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Saisissez une adresse e-mail valide.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _motDePasseController,
                            obscureText: !_motDePasseVisible,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _seConnecter(),
                            decoration:
                                decorationChamp(
                                  'Mot de passe',
                                  Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _motDePasseVisible
                                        ? 'Masquer le mot de passe'
                                        : 'Afficher le mot de passe',
                                    icon: Icon(
                                      _motDePasseVisible
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () => _motDePasseVisible =
                                          !_motDePasseVisible,
                                    ),
                                  ),
                                ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Le mot de passe est requis.'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _ouvrirRecuperation,
                              child: const Text('Mot de passe oublié ?'),
                            ),
                          ),
                          if (_erreur != null)
                            BanniereErreur(message: _erreur!),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: _chargement ? null : _seConnecter,
                              child: _chargement
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Se connecter'),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Nouveau sur la plateforme ?'),
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterScreen(),
                                  ),
                                ),
                                child: const Text('Créer un compte'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration decorationChamp(String label, IconData icon) => InputDecoration(
  labelText: label,
  prefixIcon: Icon(icon),
  filled: true,
  fillColor: const Color(0xFFF8FAFC),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
  ),
);

class _EnteteAuthentification extends StatelessWidget {
  const _EnteteAuthentification();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      CircleAvatar(
        radius: 32,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.forum_outlined, color: Colors.white, size: 32),
      ),
      SizedBox(height: 14),
      Text(
        'Messagerie & Bot',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
      SizedBox(height: 4),
      Text(
        'Réseau universitaire',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    ],
  );
}

class BanniereErreur extends StatelessWidget {
  const BanniereErreur({super.key, required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEBEE),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: AppColors.danger)),
        ),
      ],
    ),
  );
}

class _RecuperationMotDePasseSheet extends StatelessWidget {
  const _RecuperationMotDePasseSheet();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Récupération du mot de passe',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        const Text(
          'La récupération par e-mail sera disponible dès que le service de réinitialisation sera activé sur le serveur.',
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ),
      ],
    ),
  );
}
