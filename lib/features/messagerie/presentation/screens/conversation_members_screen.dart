import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_model.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';

// Écran "Voir les membres" — accessible depuis les paramètres d'un groupe.
// L'API GET des participants n'est pas encore disponible : on affiche donc
// uniquement les membres sélectionnés pendant la session courante.
class ConversationMembersScreen extends ConsumerWidget {
  final String conversationId;
  final String conversationNom;

  const ConversationMembersScreen({
    super.key,
    required this.conversationId,
    required this.conversationNom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membres = ref.watch(participantsGroupesProvider)[conversationId] ?? [];
    return Scaffold(
      appBar: AppBar(title: Text('Membres · $conversationNom')),
      body: membres.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'La liste des participants n’est pas encore disponible pour ce groupe.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              itemCount: membres.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final membre = membres[index];
                return ListTile(
                  leading: AvatarCircle(initiales: membre.initiales),
                  title: Text(membre.nomComplet),
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
      final contacts = ref.read(contactsUniversitairesProvider).valueOrNull ??
          const <AppUserModel>[];
      final nouveauxMembres = contacts
          .where((contact) => _selection.contains(contact.id))
          .toList();
      final participantsConnus = ref.read(participantsGroupesProvider);
      final membresActuels = participantsConnus[widget.conversationId] ?? [];
      ref.read(participantsGroupesProvider.notifier).state = {
        ...participantsConnus,
        widget.conversationId: [...membresActuels, ...nouveauxMembres],
      };
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
