import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/messagerie/providers/conversation_providers.dart';

class UnreadMessagesBadge extends ConsumerWidget {
  const UnreadMessagesBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadMessagesCountProvider);

    return _Badge(count: count, child: child);
  }
}

/// Nombre total de messages entrants non lus.
///
/// Ce compteur est volontairement indépendant des notifications générales :
/// les messages doivent être affichés sur l'icône « Messages » uniquement.
final unreadMessagesCountProvider = Provider<int>((ref) {
  final conversations =
      ref.watch(conversationListProvider).valueOrNull ?? const [];

  return conversations.fold<int>(
    0,
    (total, conversation) =>
        total + (conversation.nombreNonLus > 0 ? conversation.nombreNonLus : 0),
  );
});

class _Badge extends StatelessWidget {
  const _Badge({required this.count, required this.child});

  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      label: Text(count > 99 ? '99+' : '$count'),
      child: child,
    );
  }
}
