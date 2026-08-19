enum MessageType { texte, image, document, audio, video, systeme }

enum MessageStatut { enAttente, envoye, recu, lu }

// Miroir côté client de l'entité Message du backend Spring Boot.
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

  // ============================================================
  // JSON -> MessageModel
  // ============================================================

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final typeString = (json['type'] as String? ?? 'TEXTE').toUpperCase();

    final statutString = (json['statut'] as String? ?? 'ENVOYE').toUpperCase();

    return MessageModel(
      id: json['id'].toString(),

      conversationId: json['conversationId'].toString(),

      expediteurId: json['expediteurId'].toString(),

      expediteurNom: json['expediteurNom'] as String? ?? '',

      contenu: json['contenu'] as String? ?? '',

      // TEXTE / IMAGE / DOCUMENT / AUDIO / VIDEO
      type: MessageType.values.firstWhere(
        (type) => type.name.toUpperCase() == typeString,
        orElse: () => MessageType.texte,
      ),

      // EN_ATTENTE / ENVOYE / RECU / LU
      statut: MessageStatut.values.firstWhere(
        (statut) => statut.name.toUpperCase() == statutString,
        orElse: () => MessageStatut.envoye,
      ),

      dateEnvoi: _dateLocaleDepuisApi(json['dateEnvoi']?.toString()),

      messageParentId: json['messageParentId']?.toString(),
    );
  }

  // ============================================================
  // DATE API -> DATE LOCALE
  // ============================================================

  static DateTime _dateLocaleDepuisApi(String? valeur) {
    if (valeur == null || valeur.isEmpty) {
      return DateTime.now();
    }

    final contientFuseau = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(valeur);

    final date = DateTime.parse(contientFuseau ? valeur : '${valeur}Z');

    return date.toLocal();
  }

  // ============================================================
  // MessageModel -> JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'contenu': contenu,
      'type': type.name.toUpperCase(),

      if (messageParentId != null) 'messageParentId': messageParentId,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  MessageModel copyWith({
    MessageStatut? statut,
    String? contenu,
    MessageType? type,
  }) {
    return MessageModel(
      id: id,
      conversationId: conversationId,
      expediteurId: expediteurId,
      expediteurNom: expediteurNom,

      contenu: contenu ?? this.contenu,

      type: type ?? this.type,

      statut: statut ?? this.statut,

      dateEnvoi: dateEnvoi,

      messageParentId: messageParentId,
    );
  }
}
