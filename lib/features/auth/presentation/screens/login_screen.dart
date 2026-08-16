import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../messagerie/presentation/screens/conversation_list_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authRepository = AuthRepository();
  final _emailController = TextEditingController(text: 'rina@univ.mg');
  final _motDePasseController = TextEditingController(text: 'password123');
  bool _chargement = false;
  bool _motDePasseVisible = false; // <-- NOUVEAU : etat du bouton oeil
  String? _erreur;

  Future<void> _seConnecter() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      await _authRepository.login(
        _emailController.text.trim(),
        _motDePasseController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConversationListScreen()),
      );
    } on DioException catch (e) {
      setState(() {
        if (e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.unknown) {
          _erreur =
              'Impossible de joindre le serveur. Vérifie que le '
              'backend tourne et que apiHost est correct dans app_config.dart.';
        } else {
          _erreur =
              e.response?.data['erreur'] as String? ??
              'Email ou mot de passe incorrect';
        }
      });
    } catch (_) {
      setState(() => _erreur = 'Une erreur inattendue est survenue.');
    } finally {
      if (mounted) setState(() => _chargement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Messagerie & Bot',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Compte de demo pre-rempli',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motDePasseController,
                obscureText: !_motDePasseVisible, // <-- bascule ici
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _motDePasseVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _motDePasseVisible = !_motDePasseVisible);
                    },
                  ),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _chargement ? null : _seConnecter,
                child: _chargement
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Se connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
