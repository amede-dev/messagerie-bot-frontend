class AppConfig {
  AppConfig._();

  static const bool useMockBackend = false;

  // Backend deploye (prod) -> URL Render, sans port, useHttps=true
  static const String apiHost = 'messagerie-bot-backend.onrender.com';
  static const bool useHttps = true;

  static String get apiBaseUrl => '${useHttps ? "https" : "http"}://$apiHost';
  static String get wsBaseUrl => '${useHttps ? "wss" : "ws"}://$apiHost/ws';
}
