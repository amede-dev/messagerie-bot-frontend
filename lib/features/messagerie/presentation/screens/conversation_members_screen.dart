import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';

// Écran "Voir les membres" — accessible depuis les paramètres d'un groupe.
// Données factices en attendant l'endpoint réel
// GET /api/conversations/{id}/participants côté backend.
class ConversationMembersScreen extends StatelessWidget {
  final String conversationNom;

  const ConversationMembersScreen({super.key, required this.conversationNom});

  // TODO: remplacer par un vrai appel API listant les ConversationParticipant
  static const _membres = [
    {'initiales': 'HR', 'nom': 'Hery Rakoto', 'role': 'Admin'},
    {'initiales': 'CI', 'nom': 'Claudine Ihanta', 'role': 'Membre'},
    {'initiales': 'MJ', 'nom': 'Mamy Joel', 'role': 'Membre'},
    {'initiales': 'moi', 'nom': 'Moi', 'role': 'Membre'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Membres · $conversationNom')),
      body: ListView.separated(
        itemCount: _membres.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final membre = _membres[index];
          return ListTile(
            leading: AvatarCircle(initiales: membre['initiales']!),
            title: Text(membre['nom']!),
            trailing: membre['role'] == 'Admin'
                ? const Text(
                    'Admin',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  )
                : null,
          );
        },
      ),
    );
  }
}

/// Sélectionne des contacts, puis les ajoute un par un au groupe via l'API.
class AddGroupParticipantsScreen extends ConsumerStatefulWidget {
  const AddGroupParticipantsScreen({
    super.key,
    required this.conversationId,
    required this.conversationNom,
  });

  final String conversationId;
  final String conversationNom;

  @override
  ConsumerState<AddGroupParticipantsScreen> createState() =>
      _AddGroupParticipantsScreenState();
}

class _AddGroupParticipantsScreenState
    extends ConsumerState<AddGroupParticipantsScreen> {
  final Set<String> _selection = {};
  String _recherche = '';
  bool _enCours = false;

  Future<void> _ajouter() async {
    if (_selection.isEmpty) return;
    setState(() => _enCours = true);
    try {
      final repo = ref.read(conversationRepositoryProvider);
      await Future.wait(
        _selection.map(
          (utilisateurId) =>
              repo.ajouterParticipant(widget.conversationId, utilisateurId),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selection.length} participant(s) ajouté(s) au groupe.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (erreur) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible d’ajouter les participants : $erreur')),
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsUniversitairesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajouter des participants')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (valeur) => setState(() => _recherche = valeur),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: contactsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (erreur, _) => Center(child: Text('Erreur : $erreur')),
              data: (contacts) {
                final filtres = contacts
                    .where(
                      (contact) => contact.nomComplet.toLowerCase().contains(
                        _recherche.toLowerCase(),
                      ),
                    )
                    .toList();
                return ListView.builder(
                  itemCount: filtres.length,
                  itemBuilder: (context, index) {
                    final contact = filtres[index];
                    return _ContactParticipantTile(
                      contact: contact,
                      selectionne: _selection.contains(contact.id),
                      onChanged: (selectionne) => setState(() {
                        if (selectionne) {
                          _selection.add(contact.id);
                        } else {
                          _selection.remove(contact.id);
                        }
                      }),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selection.isEmpty || _enCours ? null : _ajouter,
                child: _enCours
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('Ajouter (${_selection.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactParticipantTile extends StatelessWidget {
  const _ContactParticipantTile({
    required this.contact,
    required this.selectionne,
    required this.onChanged,
  });

  final AppUserModel contact;
  final bool selectionne;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => CheckboxListTile(
    value: selectionne,
    onChanged: (valeur) => onChanged(valeur ?? false),
    secondary: AvatarCircle(initiales: contact.initiales),
    title: Text(contact.nomComplet),
    controlAffinity: ListTileControlAffinity.trailing,
  );
}
