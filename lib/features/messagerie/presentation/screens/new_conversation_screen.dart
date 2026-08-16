import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/conversation_providers.dart';

// Écran de création d'une conversation de groupe.
// Le module Gp6-4 (groupes/classes) n'existe pas encore dans cette base de
// données : pas de liaison a un espace reel possible pour l'instant.

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  final _nomController = TextEditingController();
  final Set<String> _participantsSelectionnes = {};
  bool _enCours = false;
  bool _chargementContacts = true;
  Map<String, String> _contactsDisponibles = {};

  @override
  void initState() {
    super.initState();
    _chargerContacts();
  }

  Future<void> _chargerContacts() async {
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final users = await repo.fetchUsers();
      if (!mounted) return;
      setState(() {
        _contactsDisponibles = {
          for (final u in users)
            u['id'].toString(): '${u['prenom']} ${u['nom']}',
        };
        _chargementContacts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _chargementContacts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de charger les contacts : $e')),
      );
    }
  }

  Future<void> _creerGroupe() async {
    if (_nomController.text.trim().isEmpty ||
        _participantsSelectionnes.isEmpty) {
      return;
    }
    setState(() => _enCours = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(conversationRepositoryProvider)
          .creerConversationGroupe(
            nom: _nomController.text.trim(),
            participantIds: _participantsSelectionnes.toList(),
            groupeLieId:
                null, // pas d'espace/classe reel disponible pour l'instant
          );
      await ref.read(conversationListProvider.notifier).rafraichir();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible de créer le groupe : $e')),
      );
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Nouveau groupe'),
        actions: [
          TextButton(
            onPressed: _enCours ? null : _creerGroupe,
            child: _enCours
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer'),
          ),
        ],
      ),
      body: _chargementContacts
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ajouter des participants (${_participantsSelectionnes.length} sélectionnés)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (_contactsDisponibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Aucun autre utilisateur trouvé pour le moment.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ..._contactsDisponibles.entries.map(
                  (e) => CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _participantsSelectionnes.contains(e.key),
                    onChanged: (checked) => setState(() {
                      if (checked == true) {
                        _participantsSelectionnes.add(e.key);
                      } else {
                        _participantsSelectionnes.remove(e.key);
                      }
                    }),
                    title: Text(e.value),
                  ),
                ),
              ],
            ),
    );
  }
}
