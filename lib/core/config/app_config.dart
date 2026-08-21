class AppConfig {
  AppConfig._();

  static const bool useMockBackend = false;

  // Backend deploye (prod) -> URL Render, sans port, useHttps=true
  static const String apiHost = 'messagerie-bot-backend.onrender.com';
  static const bool useHttps = true;

  static String get apiBaseUrl => '${useHttps ? "https" : "http"}://$apiHost';
  static String get wsBaseUrl => '${useHttps ? "wss" : "ws"}://$apiHost/ws';

  static String? resolveMediaUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    final uri = Uri.tryParse(value.trim());
    if (uri == null) return null;

    // Compatibilité avec les anciens messages enregistrés avec /uploads/.
    if (uri.path.startsWith('/uploads/')) {
      final nom = uri.path.substring('/uploads/'.length);
      return '$apiBaseUrl/api/files/download/$nom';
    }

    if (!uri.hasScheme || uri.host == 'localhost' || uri.host == '127.0.0.1') {
      return '$apiBaseUrl${uri.path}';
    }

    return value.trim();
  }
}
