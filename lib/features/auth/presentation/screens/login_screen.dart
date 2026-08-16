import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../../core/network/websocket_service.dart';
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
  bool _motDePasseVisible = false;
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

      // IMPORTANT : sans cet appel, le WebSocket n'etait jamais initialise
      // lors d'une connexion "fraiche" (seul le _StartupGate le faisait,
      // et uniquement si un token existait deja au demarrage de l'app).
      // C'est ce qui provoquait StompBadStateException en ouvrant un chat
      // juste apres s'etre connecte via ce formulaire.
      await WebSocketService.instance.connect();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ConversationListScreen()),
      );
    } on DioException catch (e) {
      setState(() {
        _erreur =
            e.response?.data['erreur'] as String? ??
            'Email ou mot de passe incorrect';
      });
    } catch (_) {
      setState(
        () => _erreur = 'Impossible de se connecter. Verifie ta connexion.',
      );
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
                obscureText: !_motDePasseVisible,
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
