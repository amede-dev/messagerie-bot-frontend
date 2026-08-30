import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/auth_repository.dart';
import 'core/network/websocket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/messagerie/presentation/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MessagerieApp()));
}

class MessagerieApp extends StatelessWidget {
  const MessagerieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Messagerie & Bot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),

      themeMode: ThemeMode.light,
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  final _authRepository = AuthRepository();
  bool? _connecte;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    final connecte = await _authRepository.estConnecte();
    if (connecte) {
      await WebSocketService.instance.connect();
    }
    if (mounted) setState(() => _connecte = connecte);
  }

  @override
  Widget build(BuildContext context) {
    if (_connecte == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _connecte! ? const HomeScreen() : const LoginScreen();
  }
}
