import 'message_model.dart';

enum ConversationType { privee, groupe, bot }

// Miroir côté client de l'entité `Conversation` du backend.

class ConversationModel {
  final String id;
  final ConversationType type;
  final String nom;
  final String? avatarInitiales;
  final String? groupeLieId;
  final MessageModel? dernierMessage;
  final int nombreNonLus;
  final bool enTrainDecrire;
  final bool estEnLigne;

  const ConversationModel({
    required this.id,
    required this.type,
    required this.nom,
    this.avatarInitiales,
    this.groupeLieId,
    this.dernierMessage,
    this.nombreNonLus = 0,
    this.enTrainDecrire = false,
    this.estEnLigne = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'].toString(),
      type: ConversationType.values.firstWhere(
        (t) => t.name.toUpperCase() == (json['type'] as String? ?? 'PRIVEE'),
        orElse: () => ConversationType.privee,
      ),
      nom: json['nom'] as String? ?? '',
      avatarInitiales: json['avatarInitiales'] as String?,
      groupeLieId: json['groupeLieId']?.toString(),
      dernierMessage: json['dernierMessage'] != null
          ? MessageModel.fromJson(
              json['dernierMessage'] as Map<String, dynamic>,
            )
          : null,
      nombreNonLus: json['nombreNonLus'] as int? ?? 0,
      estEnLigne: json['enLigne'] == true || json['estEnLigne'] == true,
    );
  }

  ConversationModel copyWith({
    String? nom,
    MessageModel? dernierMessage,
    int? nombreNonLus,
    bool? enTrainDecrire,
    bool? estEnLigne,
  }) {
    return ConversationModel(
      id: id,
      type: type,
      nom: nom ?? this.nom,
      avatarInitiales: avatarInitiales,
      groupeLieId: groupeLieId,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      nombreNonLus: nombreNonLus ?? this.nombreNonLus,
      enTrainDecrire: enTrainDecrire ?? this.enTrainDecrire,
      estEnLigne: estEnLigne ?? this.estEnLigne,
    );
  }
}
