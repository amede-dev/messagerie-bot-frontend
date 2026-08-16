class AppConfig {
  AppConfig._();

  static const bool useMockBackend = false;

  // --- A ADAPTER selon ton contexte de test ---
  // Emulateur Android      -> '10.0.2.2:8080'
  // Simulateur iOS         -> 'localhost:8080'
  // Telephone physique     -> IP locale de ton PC, ex '192.168.1.12:8080'
  static const String apiHost = '10.0.2.2:8080';
  static const bool useHttps = false;

  static String get apiBaseUrl => '${useHttps ? "https" : "http"}://$apiHost';
  static String get wsBaseUrl => '${useHttps ? "wss" : "ws"}://$apiHost/ws';
}