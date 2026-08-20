import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../messagerie/presentation/screens/home_screen.dart';
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

  String _role = 'ETUDIANT';
  String _parcours = 'GLBD';
  String _niveau = 'L1';

  static const _parcoursEni = <String, String>{
    'GLBD': 'Génie Logiciel et Base de Données',
    'ASR': 'Administration des Systèmes et Réseaux',
    'IG': 'Informatique Générale',
    'GID': 'Gouvernance et Ingénierie de Données',
    'OCC': 'Objets Connectés et Cybersécurité',
  };

  static const _niveauxEni = <String, String>{
    'L1': 'Licence 1',
    'L2': 'Licence 2',
    'L3': 'Licence 3',
    'M1': 'Master 1',
    'M2': 'Master 2',
  };

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _motDePasseController.dispose();
    _confirmationController.dispose();
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
        role: _role,
        parcours: _parcours,
        niveau: _niveau,
      );

      await WebSocketService.instance.connect();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
      if (mounted) {
        setState(() => _chargement = false);
      }
    }
  }

  String? _requis(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'Ce champ est requis.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Créer un compte')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final hauteurMinimum = (constraints.maxHeight - 64).clamp(
              0.0,
              double.infinity,
            );

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 460,
                    minHeight: hauteurMinimum,
                  ),
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
                          'Renseignez votre parcours ENI et votre niveau pour créer votre profil.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 28),

                        TextFormField(
                          controller: _nomController,
                          style: styleTexteSaisi,
                          cursorColor: AppColors.primary,
                          textCapitalization: TextCapitalization.words,
                          decoration: decorationChamp(
                            'Nom',
                            Icons.badge_outlined,
                          ),
                          validator: _requis,
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _prenomController,
                          style: styleTexteSaisi,
                          cursorColor: AppColors.primary,
                          textCapitalization: TextCapitalization.words,
                          decoration: decorationChamp(
                            'Prénom',
                            Icons.person_outline,
                          ),
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
                            Icons.email_outlined,
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Saisissez une adresse e-mail valide.'
                              : null,
                        ),

                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          value: _role,
                          isExpanded: true,
                          menuMaxHeight: 260,
                          decoration: decorationChamp(
                            'Rôle universitaire',
                            Icons.school_outlined,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'ETUDIANT',
                              child: Text(
                                'Étudiant',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ENSEIGNANT',
                              child: Text(
                                'Enseignant',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (role) {
                            if (role != null) {
                              setState(() => _role = role);
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          value: _parcours,
                          isExpanded: true,
                          menuMaxHeight: 260,
                          decoration: decorationChamp(
                            'Parcours en informatique ENI',
                            Icons.code_outlined,
                          ),
                          items: _parcoursEni.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (parcours) {
                            if (parcours != null) {
                              setState(() => _parcours = parcours);
                            }
                          },
                        ),

                        const SizedBox(height: 14),

                        DropdownButtonFormField<String>(
                          value: _niveau,
                          isExpanded: true,
                          menuMaxHeight: 260,
                          decoration: decorationChamp(
                            'Niveau d’études',
                            Icons.layers_outlined,
                          ),
                          items: _niveauxEni.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(
                                    entry.value,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (niveau) {
                            if (niveau != null) {
                              setState(() => _niveau = niveau);
                            }
                          },
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
                                  tooltip: _motDePasseVisible
                                      ? 'Masquer le mot de passe'
                                      : 'Afficher le mot de passe',
                                  icon: Icon(
                                    _motDePasseVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _motDePasseVisible =
                                          !_motDePasseVisible,
                                    );
                                  },
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
            );
          },
        ),
      ),
    );
  }
}
