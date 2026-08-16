import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/conversation_providers.dart';
import 'chat_screen.dart';

// Ecran de creation. Un tap sur le NOM d'un contact demarre directement
// une discussion privee. La case a cocher sert a construire un groupe.
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

  Future<void> _ouvrirDiscussionPrivee(String userId) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final conversation = await ref
          .read(conversationRepositoryProvider)
          .creerConversationPrivee(userId);
      await ref.read(conversationListProvider.notifier).rafraichir();
      if (!mounted) return;
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(conversation: conversation),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Impossible de démarrer la discussion : $e')),
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
            groupeLieId: null,
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
        title: const Text('Nouvelle discussion'),
        actions: [
          TextButton(
            onPressed: _enCours ? null : _creerGroupe,
            child: _enCours
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Créer le groupe'),
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
                    labelText:
                        'Nom du groupe (optionnel pour discussion privée)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Touche un nom pour démarrer une discussion privée, '
                  'ou coche plusieurs contacts + un nom pour créer un groupe.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                if (_contactsDisponibles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Aucun autre utilisateur trouvé pour le moment.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ..._contactsDisponibles.entries.map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(e.value.isNotEmpty ? e.value[0] : '?'),
                    ),
                    title: Text(e.value),
                    onTap: () => _ouvrirDiscussionPrivee(e.key),
                    trailing: Checkbox(
                      value: _participantsSelectionnes.contains(e.key),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _participantsSelectionnes.add(e.key);
                        } else {
                          _participantsSelectionnes.remove(e.key);
                        }
                      }),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
