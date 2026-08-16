import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/auth_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../bot/presentation/screens/bot_chat_screen.dart';
import '../../providers/conversation_providers.dart';
import '../widgets/conversation_tile.dart';
import 'chat_screen.dart';
import 'new_conversation_screen.dart';

// Écran d'accueil du module Messagerie.
// Le bot est toujours épinglé en première position.
// Contient une barre de recherche qui filtre les conversations par nom.
class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() =>
      _ConversationListScreenState();
}

class _ConversationListScreenState
    extends ConsumerState<ConversationListScreen> {
  final _rechercheController = TextEditingController();
  final _authRepository = AuthRepository();
  String _recherche = '';

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  Future<void> _seDeconnecter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Tu devras te reconnecter pour accéder à tes conversations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Se déconnecter',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    await _authRepository.deconnexion();

    if (!mounted) return;
    // pushAndRemoveUntil vide toute la pile de navigation : le bouton
    // "retour" du telephone ne pourra plus revenir vers les ecrans
    // authentifies apres deconnexion.
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationListProvider);
    const nomBot = 'Assistant Uni';
    final botCorrespond = nomBot.toLowerCase().contains(
      _recherche.toLowerCase(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: _seDeconnecter,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const NewConversationScreen(),
                ),
              ),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF3A3A3C),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_square,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Barre de recherche : fond noir, texte et icônes en blanc ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: _rechercheController,
              onChanged: (val) => setState(() => _recherche = val),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
              decoration: InputDecoration(
                hintText: 'Rechercher',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                suffixIcon: _recherche.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => setState(() {
                          _rechercheController.clear();
                          _recherche = '';
                        }),
                      ),
                filled: true,
                fillColor: Colors.black,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: conversationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Erreur de chargement : $err')),
              data: (conversationsBrutes) {
                final conversations = _recherche.isEmpty
                    ? conversationsBrutes
                    : conversationsBrutes
                          .where(
                            (c) => c.nom.toLowerCase().contains(
                              _recherche.toLowerCase(),
                            ),
                          )
                          .toList();

                final itemCount =
                    conversations.length + (botCorrespond ? 1 : 0);

                if (itemCount == 0) {
                  return const Center(
                    child: Text('Aucune conversation trouvée'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(conversationListProvider.notifier).rafraichir(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (botCorrespond && index == 0) {
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: const CircleAvatar(
                            child: Icon(Icons.smart_toy_outlined),
                          ),
                          title: const Text(
                            nomBot,
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: const Text('Bot · toujours disponible'),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BotChatScreen(),
                            ),
                          ),
                        );
                      }
                      final conversation =
                          conversations[index - (botCorrespond ? 1 : 0)];
                      return ConversationTile(
                        conversation: conversation,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ChatScreen(conversation: conversation),
                          ),
                        ),
                      );
                    },
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
