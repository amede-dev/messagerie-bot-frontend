import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../features/messagerie/providers/conversation_providers.dart';

class UnreadMessagesBadge extends ConsumerWidget {
  const UnreadMessagesBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationListProvider).valueOrNull ?? [];
    final count = conversations.fold<int>(
      0,
      (total, conversation) => total + conversation.nombreNonLus,
    );

    return _Badge(count: count, child: child);
  }
}

class UnreadNotificationsBadge extends StatefulWidget {
  const UnreadNotificationsBadge({super.key, required this.child});

  final Widget child;

  @override
  State<UnreadNotificationsBadge> createState() =>
      _UnreadNotificationsBadgeState();
}

class _UnreadNotificationsBadgeState extends State<UnreadNotificationsBadge> {
  int _count = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _charger());
  }

  Future<void> _charger() async {
    try {
      final response = await ApiClient.instance.getNotifications();
      final notifications = response.data as List<dynamic>;
      final count = notifications
          .where((notification) => notification['lu'] != true)
          .length;
      if (mounted) setState(() => _count = count);
    } catch (_) {
      // L'absence temporaire du backend ne doit pas bloquer la navigation.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Badge(count: _count, child: widget.child);
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
