import 'message_model.dart';
import '../utils/api_date_time.dart';

enum ConversationType { privee, bot }

// Miroir côté client de l'entité `Conversation` du backend.
class ConversationModel {
  final String id;

  final ConversationType type;

  final String nom;

  final String? avatarInitiales;

  final MessageModel? dernierMessage;

  final int nombreNonLus;

  final bool enTrainDecrire;

  final bool estEnLigne;

  // ==========================================================================
  // ID DE L'AUTRE UTILISATEUR
  // ==========================================================================
  //
  // Utilisé uniquement pour les conversations privées.
  //
  // Exemple :
  //
  // conversation = Marie
  // utilisateurId = "15"
  //
  // Cela permet de recevoir :
  //
  // Presence utilisateurId = "15"
  //
  // et de savoir que cette présence concerne Marie.
  //
  final String? utilisateurId;

  final String? photoUrl;

  // ==========================================================================
  // DERNIÈRE CONNEXION
  // ==========================================================================

  final DateTime? derniereConnexion;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.nom,

    this.avatarInitiales,
    this.dernierMessage,

    this.nombreNonLus = 0,

    this.enTrainDecrire = false,

    this.estEnLigne = false,

    this.utilisateurId,

    this.photoUrl,

    this.derniereConnexion,
  });

  // ==========================================================================
  // JSON → CONVERSATION MODEL
  // ==========================================================================

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      // -----------------------------------------------------------------------
      // ID conversation
      // -----------------------------------------------------------------------
      id: json['id'].toString(),

      // -----------------------------------------------------------------------
      // Type
      // -----------------------------------------------------------------------
      type: ConversationType.values.firstWhere(
        (t) => t.name.toUpperCase() == (json['type'] as String? ?? 'PRIVEE'),

        orElse: () => ConversationType.privee,
      ),

      // -----------------------------------------------------------------------
      // Nom
      // -----------------------------------------------------------------------
      nom: json['nom'] as String? ?? '',

      // -----------------------------------------------------------------------
      // Initiales
      // -----------------------------------------------------------------------
      avatarInitiales: json['avatarInitiales'] as String?,

      // -----------------------------------------------------------------------
      // -----------------------------------------------------------------------
      // Dernier message
      // -----------------------------------------------------------------------
      dernierMessage: json['dernierMessage'] != null
          ? MessageModel.fromJson(
              json['dernierMessage'] as Map<String, dynamic>,
            )
          : null,

      // -----------------------------------------------------------------------
      // Messages non lus
      // -----------------------------------------------------------------------
      nombreNonLus: json['nombreNonLus'] as int? ?? 0,

      // -----------------------------------------------------------------------
      // ID DE L'AUTRE UTILISATEUR
      // -----------------------------------------------------------------------
      utilisateurId: json['utilisateurId']?.toString(),

      // Le backend renvoie normalement photoUrl. Le fallback permet aussi
      // d'afficher la photo déjà enregistrée lorsque cette valeur manque dans
      // une ancienne réponse de conversation.
      photoUrl: json['photoUrl'] as String? ??
          (json['utilisateurId'] != null
              ? '/api/users/${json['utilisateurId']}/photo'
              : null),

      // -----------------------------------------------------------------------
      // EN LIGNE
      // -----------------------------------------------------------------------
      estEnLigne: json['enLigne'] == true || json['estEnLigne'] == true,

      // -----------------------------------------------------------------------
      // DERNIÈRE CONNEXION
      // -----------------------------------------------------------------------
      derniereConnexion: json['derniereConnexion'] != null
          ? ApiDateTime.parse(json['derniereConnexion'].toString())
          : null,
    );
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  ConversationModel copyWith({
    String? nom,

    MessageModel? dernierMessage,

    int? nombreNonLus,

    bool? enTrainDecrire,

    bool? estEnLigne,

    String? utilisateurId,

    String? photoUrl,

    DateTime? derniereConnexion,
  }) {
    return ConversationModel(
      id: id,

      type: type,

      nom: nom ?? this.nom,

      avatarInitiales: avatarInitiales,

      dernierMessage: dernierMessage ?? this.dernierMessage,

      nombreNonLus: nombreNonLus ?? this.nombreNonLus,

      enTrainDecrire: enTrainDecrire ?? this.enTrainDecrire,

      estEnLigne: estEnLigne ?? this.estEnLigne,

      utilisateurId: utilisateurId ?? this.utilisateurId,

      photoUrl: photoUrl ?? this.photoUrl,

      derniereConnexion: derniereConnexion ?? this.derniereConnexion,
    );
  }
}
