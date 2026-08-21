/// Conversion des dates produites par Spring Boot.
///
/// Le backend utilise LocalDateTime et ne sérialise donc pas de fuseau horaire.
/// Dans l'environnement déployé, cette valeur correspond à UTC. Elle doit être
/// convertie vers l'heure locale du téléphone avant l'affichage.
class ApiDateTime {
  ApiDateTime._();

  static DateTime? parse(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final text = value.trim();
    final containsTimezone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(text);
    final parsed = DateTime.tryParse(containsTimezone ? text : '${text}Z');

    return parsed?.toLocal();
  }
}
