// Conversion des dates produites par Spring Boot.
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
