enum MessageType { texte, image, document, systeme }

enum MessageStatut { enAttente, envoye, recu, lu }

// Miroir côté client de l'entité `Message` du backend Spring Boot.
class MessageModel {
  final String id;
  final String conversationId;
  final String expediteurId;
  final String expediteurNom;
  final String contenu;
  final MessageType type;
  final MessageStatut statut;
  final DateTime dateEnvoi;
  final String? messageParentId;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.expediteurId,
    required this.expediteurNom,
    required this.contenu,
    required this.type,
    required this.statut,
    required this.dateEnvoi,
    this.messageParentId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'].toString(),
      conversationId: json['conversationId'].toString(),
      expediteurId: json['expediteurId'].toString(),
      expediteurNom: json['expediteurNom'] as String? ?? '',
      contenu: json['contenu'] as String? ?? '',
      type: MessageType.values.firstWhere(
        (t) => t.name.toUpperCase() == (json['type'] as String? ?? 'TEXTE'),
        orElse: () => MessageType.texte,
      ),
      statut: MessageStatut.values.firstWhere(
        (s) => s.name.toUpperCase() == (json['statut'] as String? ?? 'ENVOYE'),
        orElse: () => MessageStatut.envoye,
      ),
      dateEnvoi: DateTime.parse(json['dateEnvoi'] as String),
      messageParentId: json['messageParentId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'conversationId': conversationId,
    'contenu': contenu,
    'type': type.name.toUpperCase(),
    if (messageParentId != null) 'messageParentId': messageParentId,
  };

  MessageModel copyWith({MessageStatut? statut}) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      expediteurId: expediteurId,
      expediteurNom: expediteurNom,
      contenu: contenu,
      type: type,
      statut: statut ?? this.statut,
      dateEnvoi: dateEnvoi,
      messageParentId: messageParentId,
    );
  }
}
