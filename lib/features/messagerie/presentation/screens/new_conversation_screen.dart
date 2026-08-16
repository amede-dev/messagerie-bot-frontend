import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/conversation_providers.dart';

// Écran de création d'une conversation de groupe, avec liaison optionnelle
// à un espace de classe/club existant.

class NewConversationScreen extends ConsumerStatefulWidget {
  const NewConversationScreen({super.key});

  @override
  ConsumerState<NewConversationScreen> createState() =>
      _NewConversationScreenState();
}

class _NewConversationScreenState extends ConsumerState<NewConversationScreen> {
  final _nomController = TextEditingController();
  String? _groupeLieId;
  final Set<String> _participantsSelectionnes = {};
  bool _enCours = false;

  // TODO: remplacer par la vraie liste issue du module Gp6-4 / annuaire utilisateurs
  final _espacesDisponibles = const {'classe-l2i': 'Classe L2 Informatique'};
  final _contactsDisponibles = const {
    'u1': 'Hery Rakoto',
    'u2': 'Claudine Ihanta',
    'u3': 'Mamy Joel',
  };

  Future<void> _creerGroupe() async {
    if (_nomController.text.trim().isEmpty || _participantsSelectionnes.isEmpty)
      return;
    setState(() => _enCours = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(conversationRepositoryProvider)
          .creerConversationGroupe(
            nom: _nomController.text.trim(),
            participantIds: _participantsSelectionnes.toList(),
            groupeLieId: _groupeLieId,
          );
      await ref.read(conversationListProvider.notifier).rafraichir();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de créer le groupe. Vérifie ta connexion et réessaie.',
          ),
        ),
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
      body: ListView(
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
          const Text(
            'Lier à un espace existant',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          ..._espacesDisponibles.entries.map(
            (e) => RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: e.key,
              groupValue: _groupeLieId,
              onChanged: (val) => setState(() => _groupeLieId = val),
              title: Text(e.value),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ajouter des participants (${_participantsSelectionnes.length} sélectionnés)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
