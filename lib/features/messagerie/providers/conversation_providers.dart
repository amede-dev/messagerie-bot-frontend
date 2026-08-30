import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/app_user_model.dart';
import '../../../core/models/conversation_model.dart';
import '../../../core/models/message_model.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/network/auth_repository.dart';
import '../data/conversation_repository.dart';

import '../../../core/network/file_upload_service.dart';

// REPOSITORY
final conversationRepositoryProvider = Provider(
  (ref) => ConversationRepository(),
);

// CONTACTS UNIVERSITAIRES
final contactsUniversitairesProvider = FutureProvider<List<AppUserModel>>((
  ref,
) async {
  final contacts = await ref.read(conversationRepositoryProvider).fetchUsers();

  contacts.sort(
    (a, b) => a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase()),
  );

  return contacts;
});

// LISTE DES CONVERSATIONS
final conversationListProvider =
    AsyncNotifierProvider<ConversationListNotifier, List<ConversationModel>>(
      ConversationListNotifier.new,
    );

class ConversationListNotifier extends AsyncNotifier<List<ConversationModel>> {
  StreamSubscription<MessageModel>? _messageSubscription;

  StreamSubscription<PresenceModel>? _presenceSubscription;
  String? _utilisateurCourantId;

  // TRI DES CONVERSATIONS
  List<ConversationModel> _trierConversations(
    List<ConversationModel> conversations,
  ) {
    final resultat = List<ConversationModel>.from(conversations);

    resultat.sort((a, b) {
      final dateA = a.dernierMessage?.dateEnvoi;

      final dateB = b.dernierMessage?.dateEnvoi;

      if (dateA == null && dateB == null) {
        return 0;
      }

      if (dateA == null) {
        return 1;
      }

      if (dateB == null) {
        return -1;
      }

      return dateB.compareTo(dateA);
    });

    return resultat;
  }

  // BUILD

  @override
  Future<List<ConversationModel>> build() async {
    _utilisateurCourantId = await AuthRepository().idUtilisateurConnecte();
    // Écouter les nouveaux messages

    // Écouter les nouveaux messages
    _messageSubscription ??= WebSocketService.instance.messageStream.listen(
      _traiterNouveauMessage,
    );

    // Écouter la présence

    _presenceSubscription ??= WebSocketService.instance.presenceStream.listen(
      _traiterPresence,
    );

    // Nettoyage

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _presenceSubscription?.cancel();

      _messageSubscription = null;
      _presenceSubscription = null;
    });

    // Charger les conversations

    final conversations = await ref
        .read(conversationRepositoryProvider)
        .fetchConversations();

    return _trierConversations(conversations);
  }

  // RAFRAÎCHIR

  Future<void> rafraichir() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final conversations = await ref
          .read(conversationRepositoryProvider)
          .fetchConversations();

      return _trierConversations(conversations);
    });
  }

  // NOUVEAU MESSAGE REÇU

  void _traiterNouveauMessage(MessageModel message) {
    final actuel = state.valueOrNull;

    if (actuel == null) {
      return;
    }

    final index = actuel.indexWhere(
      (conversation) => conversation.id == message.conversationId,
    );

    if (index == -1) {
      rafraichir();
      return;
    }

    final conversation = actuel[index];

    if (conversation.dernierMessage?.id == message.id) {
      final precedent = conversation.dernierMessage;
      if (precedent?.statut != message.statut ||
          precedent?.contenu != message.contenu ||
          precedent?.type != message.type ||
          precedent?.expediteurPhotoUrl != message.expediteurPhotoUrl) {
        final nouvelleListe = List<ConversationModel>.from(actuel);
        nouvelleListe[index] = conversation.copyWith(dernierMessage: message);
        state = AsyncData(nouvelleListe);
      }
      return;
    }

    final dernier = conversation.dernierMessage;

    if (dernier != null && message.dateEnvoi.isBefore(dernier.dateEnvoi)) {
      return;
    }

    var nombreNonLus = conversation.nombreNonLus;

    if (message.expediteurId != _utilisateurCourantId &&
        message.statut != MessageStatut.lu) {
      nombreNonLus++;
    }

    final conversationMiseAJour = conversation.copyWith(
      dernierMessage: message,
      nombreNonLus: nombreNonLus,
    );

    final nouvelleListe = List<ConversationModel>.from(actuel);

    nouvelleListe[index] = conversationMiseAJour;

    // Le nouveau message place la conversation
    state = AsyncData(_trierConversations(nouvelleListe));
  }

  // PRÉSENCE

  void _traiterPresence(PresenceModel presence) {
    final actuel = state.valueOrNull;

    if (actuel == null) {
      return;
    }

    final nouvelleListe = actuel.map((conversation) {
      // La présence est suivie uniquement pour les conversations privées.

      if (conversation.type != ConversationType.privee) {
        return conversation;
      }

      // Vérifier que cette conversation correspond à l'utilisateur concerné.

      if (conversation.utilisateurId != presence.utilisateurId) {
        return conversation;
      }

      // Mettre à jour la présence.
      return ConversationModel(
        id: conversation.id,
        type: conversation.type,
        nom: conversation.nom,
        avatarInitiales: conversation.avatarInitiales,
        dernierMessage: conversation.dernierMessage,
        nombreNonLus: conversation.nombreNonLus,
        enTrainDecrire: conversation.enTrainDecrire,
        photoUrl: conversation.photoUrl,

        utilisateurId: conversation.utilisateurId,

        estEnLigne: presence.enLigne,

        derniereConnexion: presence.derniereConnexion,
      );
    }).toList();

    state = AsyncData(_trierConversations(nouvelleListe));
  }

  // RETIRER UNE CONVERSATION

  void retirerConversation(String conversationId) {
    final actuel = state.valueOrNull;

    if (actuel == null) {
      return;
    }

    final nouvelleListe = actuel
        .where((conversation) => conversation.id != conversationId)
        .toList();

    state = AsyncData(_trierConversations(nouvelleListe));
  }

  // MARQUER COMME LUE

  void marquerConversationLue(String conversationId) {
    final actuel = state.valueOrNull;

    if (actuel == null) {
      return;
    }

    final nouvelleListe = actuel
        .map(
          (conversation) => conversation.id == conversationId
              ? conversation.copyWith(nombreNonLus: 0)
              : conversation,
        )
        .toList();

    state = AsyncData(_trierConversations(nouvelleListe));
  }

  // RENOMMER

  void renommerConversation(String conversationId, String nom) {
    final actuel = state.valueOrNull;

    if (actuel == null) {
      return;
    }

    final nouvelleListe = actuel
        .map(
          (conversation) => conversation.id == conversationId
              ? conversation.copyWith(nom: nom)
              : conversation,
        )
        .toList();

    state = AsyncData(_trierConversations(nouvelleListe));
  }

  // Met à jour immédiatement le dernier message dans l'accueil et la liste
  void mettreAJourMessage(MessageModel message) {
    final actuel = state.valueOrNull;
    if (actuel == null) return;

    final nouvelleListe = actuel.map((conversation) {
      if (conversation.id != message.conversationId) return conversation;
      return conversation.copyWith(dernierMessage: message);
    }).toList();

    state = AsyncData(_trierConversations(nouvelleListe));
  }
}

// MESSAGES D'UNE CONVERSATION

final chatMessagesProvider =
    AsyncNotifierProvider.family<
      ChatMessagesNotifier,
      List<MessageModel>,
      String
    >(ChatMessagesNotifier.new);

class ChatMessagesNotifier
    extends FamilyAsyncNotifier<List<MessageModel>, String> {
  StreamSubscription<MessageModel>? _messageSubscription;
  StreamSubscription<MessageSuppressionModel>? _suppressionSubscription;
  int _page = 0;
  bool _chargementPagePrecedente = false;
  bool _aEncoreDesMessages = true;

  // BUILD

  @override
  Future<List<MessageModel>> build(String conversationId) async {
    WebSocketService.instance.subscribeToConversation(conversationId);

    _messageSubscription = WebSocketService.instance.messageStream.listen((
      message,
    ) {
      if (message.conversationId == conversationId) {
        _ajouterMessage(message);
      }
    });
    _suppressionSubscription = WebSocketService
        .instance
        .messageSuppressionStream
        .listen((suppression) {
          supprimerMessageLocalement(suppression.messageId);
        });

    ref.onDispose(() {
      _messageSubscription?.cancel();
      _suppressionSubscription?.cancel();
      _messageSubscription = null;
      _suppressionSubscription = null;
    });

    final repo = ref.read(conversationRepositoryProvider);

    final historique = await repo.fetchMessages(conversationId);
    _page = 0;
    _aEncoreDesMessages = historique.length >= 30;

    return historique;
  }

  Future<void> chargerMessagesPlusAnciens() async {
    if (_chargementPagePrecedente || !_aEncoreDesMessages) return;

    _chargementPagePrecedente = true;
    try {
      final anciens = await ref
          .read(conversationRepositoryProvider)
          .fetchMessages(arg, page: _page + 1);

      _page++;
      _aEncoreDesMessages = anciens.length >= 30;

      final actuels = state.valueOrNull ?? const <MessageModel>[];
      final idsExistants = actuels.map((message) => message.id).toSet();
      final nouveauxAnciens = anciens
          .where((message) => !idsExistants.contains(message.id))
          .toList();

      state = AsyncData([...nouveauxAnciens, ...actuels]);
    } finally {
      _chargementPagePrecedente = false;
    }
  }

  // AJOUTER UN MESSAGE
  void _ajouterMessage(MessageModel message) {
    final actuel = state.valueOrNull ?? [];

    final indexExistant = actuel.indexWhere((m) => m.id == message.id);

    if (indexExistant != -1) {
      final precedent = actuel[indexExistant];
      if (precedent.statut != message.statut ||
          precedent.contenu != message.contenu ||
          precedent.type != message.type ||
          precedent.expediteurPhotoUrl != message.expediteurPhotoUrl) {
        final miseAJour = List<MessageModel>.from(actuel);
        miseAJour[indexExistant] = message;
        state = AsyncData(miseAJour);
      }
      return;
    }

    state = AsyncData([...actuel, message]);
  }

  // SUPPRIMER LOCALEMENT

  void supprimerMessageLocalement(String messageId) {
    final actuel = state.valueOrNull ?? const <MessageModel>[];

    state = AsyncData(
      actuel.where((message) => message.id != messageId).toList(),
    );
  }

  // ENVOYER

  Future<void> envoyer(String texte) async {
    final message = await ref
        .read(conversationRepositoryProvider)
        .envoyerMessage(arg, texte);
    _ajouterMessage(message);
  }

  Future<void> modifierMessage(String messageId, String contenu) async {
    final message = await ref
        .read(conversationRepositoryProvider)
        .modifierMessage(messageId, contenu);
    _ajouterMessage(message);
    ref.read(conversationListProvider.notifier).mettreAJourMessage(message);
  }

  // MARQUER LU

  Future<void> marquerMessagesEntrantsCommeLus(
    String utilisateurCourantId,
  ) async {
    final messagesEntrants = (state.valueOrNull ?? const <MessageModel>[])
        .where(
          (message) =>
              message.expediteurId != utilisateurCourantId &&
              message.statut != MessageStatut.lu,
        )
        .toList();

    if (messagesEntrants.isEmpty) {
      return;
    }

    final repo = ref.read(conversationRepositoryProvider);

    await Future.wait(
      messagesEntrants.map((message) => repo.marquerMessageLu(message.id)),
    );

    final idsLus = messagesEntrants.map((message) => message.id).toSet();

    final actuel = state.valueOrNull ?? const <MessageModel>[];

    state = AsyncData(
      actuel
          .map(
            (message) => idsLus.contains(message.id)
                ? message.copyWith(statut: MessageStatut.lu)
                : message,
          )
          .toList(),
    );
  }

  // PIÈCE JOINTE

  Future<void> envoyerFichier(File fichier, MessageType type) async {
    final fichierEnvoye = await FileUploadService.instance.upload(fichier);

    // L'URL du fichier est enregistrée comme message via REST.
    final message = await ref
        .read(conversationRepositoryProvider)
        .envoyerMessage(arg, fichierEnvoye.url, type: type);

    _ajouterMessage(message);
  }

  // EN TRAIN D'ÉCRIRE

  void notifierFrappe() {
    WebSocketService.instance.notifierEnTrainDecrire(arg);
  }
}
