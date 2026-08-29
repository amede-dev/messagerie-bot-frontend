import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/app_user_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/avatar_circle.dart';
import '../../providers/conversation_providers.dart';
import 'chat_screen.dart';

// Écran « Nouvelle discussion » : carnet de contacts affichant tous les utilisateurs 

class ContactListScreen extends ConsumerStatefulWidget {
  const ContactListScreen({super.key});

  @override
  ConsumerState<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends ConsumerState<ContactListScreen> {
  final _rechercheController = TextEditingController();
  String _recherche = '';

  bool _chargement = true;
  String? _erreur;
  List<AppUserModel> _contacts = [];

  // Identifiant du contact sur lequel on vient de taper 
  String? _idEnCoursDeCreation;

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
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final repo = ref.read(conversationRepositoryProvider);
      final utilisateurs = await repo.fetchUsers();
      // Tri alphabétique par nom de famille, comme un carnet de contacts.
      utilisateurs.sort(
        (a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()),
      );
      if (!mounted) return;
      setState(() {
        _contacts = utilisateurs;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = '$e';
        _chargement = false;
      });
    }
  }

  List<AppUserModel> get _contactsFiltres {
    if (_recherche.trim().isEmpty) return _contacts;
    final q = _recherche.trim().toLowerCase();
    return _contacts
        .where((u) => u.nomComplet.toLowerCase().contains(q))
        .toList();
  }

  // Récupère l'identifiant du contact sélectionné et lance la conversation privée
  Future<void> _demarrerConversationAvec(AppUserModel contact) async {
    if (_idEnCoursDeCreation != null) return; // évite le double-tap
    setState(() => _idEnCoursDeCreation = contact.id);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final conversation = await ref
          .read(conversationRepositoryProvider)
          .creerConversationPrivee(contact.id);

      // Rafraîchit la liste d'accueil pour que la discussion 
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
      if (mounted) setState(() => _idEnCoursDeCreation = null);
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
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _rechercheController,
              onChanged: (val) => setState(() => _recherche = val),
              decoration: InputDecoration(
                hintText: 'Rechercher un contact',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _recherche.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _rechercheController.clear();
                          _recherche = '';
                        }),
                      ),
                filled: true,
                fillColor: AppColors.bgLight,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(child: _corps()),
        ],
      ),
    );
  }

  Widget _corps() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              const Text(
                'Le serveur met parfois jusqu\'à deux minutes à '
                'se réveiller (offre gratuite Render).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$_erreur',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _chargerContacts,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_contactsFiltres.isEmpty) {
      return const Center(child: Text('Aucun contact trouvé'));
    }

    return RefreshIndicator(
      onRefresh: _chargerContacts,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: _contactsFiltres.length,
        itemBuilder: (context, index) => _ligneContact(_contactsFiltres[index]),
      ),
    );
  }

  Widget _ligneContact(AppUserModel contact) {
    final enCours = _idEnCoursDeCreation == contact.id;
    return ListTile(
      leading: AvatarCircle(
        initiales: contact.initiales,
        imageUrl: contact.photoUrl,
        estEnLigne: contact.enLigne,
      ),
      title: Text(contact.nomComplet),
      trailing: enCours
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: enCours ? null : () => _demarrerConversationAvec(contact),
    );
  }
}
