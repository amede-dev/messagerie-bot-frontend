import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_model.dart';
import '../../../../core/models/message_model.dart';
import '../../../../core/network/websocket_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';

// Sélectionne un contact et transmet une copie du message dans sa discussion.
class ForwardMessageScreen extends ConsumerStatefulWidget {
  const ForwardMessageScreen({super.key, required this.message});

  final MessageModel message;

  @override
  ConsumerState<ForwardMessageScreen> createState() =>
      _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends ConsumerState<ForwardMessageScreen> {
  final _rechercheController = TextEditingController();
  List<AppUserModel> _contacts = [];
  String _recherche = '';
  String? _envoiEnCours;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _chargerContacts();
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _chargerContacts() async {
    try {
      final contacts = await ref
          .read(conversationRepositoryProvider)
          .fetchUsers();
      contacts.sort(
        (a, b) =>
            a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase()),
      );
      if (mounted) setState(() => _contacts = contacts);
    } catch (_) {
      if (mounted)
        setState(() => _erreur = 'Impossible de charger les contacts.');
    }
  }

  Future<void> _transferer(AppUserModel contact) async {
    if (_envoiEnCours != null) return;
    setState(() => _envoiEnCours = contact.id);
    try {
      final conversation = await ref
          .read(conversationRepositoryProvider)
          .creerConversationPrivee(contact.id);
      await WebSocketService.instance.envoyerMessage(
        conversationId: conversation.id,
        contenu: widget.message.contenu,
        type: widget.message.type,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message envoyé à ${contact.nomComplet}.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _erreur = 'Impossible de transférer le message.');
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = _contacts
        .where(
          (contact) => contact.nomComplet.toLowerCase().contains(
            _recherche.trim().toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Transférer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _rechercheController,
              onChanged: (valeur) => setState(() => _recherche = valeur),
              decoration: const InputDecoration(
                hintText: 'Rechercher',
                prefixIcon: Icon(Icons.search),
                filled: true,
              ),
            ),
          ),
          if (_erreur != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _erreur!,
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
          Expanded(
            child: _contacts.isEmpty && _erreur == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final enCours = _envoiEnCours == contact.id;
                      return ListTile(
                        leading: AvatarCircle(initiales: contact.initiales),
                        title: Text(contact.nomComplet),
                        trailing: enCours
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : FilledButton(
                                onPressed: () => _transferer(contact),
                                child: const Text('Envoyer'),
                              ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
