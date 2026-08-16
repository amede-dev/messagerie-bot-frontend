// Réponse renvoyée par POST /api/bot/message
class BotResponseModel {
  final String texte;
  final List<String> suggestions; // boutons de réponse rapide (chips)
  final bool escaladeHumaine;

  const BotResponseModel({
    required this.texte,
    this.suggestions = const [],
    this.escaladeHumaine = false,
  });

  factory BotResponseModel.fromJson(Map<String, dynamic> json) {
    return BotResponseModel(
      texte: json['texte'] as String? ?? '',
      suggestions: (json['suggestions'] as List?)?.cast<String>() ?? const [],
      escaladeHumaine: json['escaladeHumaine'] as bool? ?? false,
    );
  }
}
