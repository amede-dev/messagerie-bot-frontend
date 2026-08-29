import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// interlocuteur est en train d'écrire.
class TypingIndicator extends StatefulWidget {
  final String nomUtilisateur;

  const TypingIndicator({super.key, required this.nomUtilisateur});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [...List.generate(3, (i) => _buildDot(i))],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final decalage = (index * 0.2);
        final valeur = ((_controller.value + decalage) % 1.0);
        final opacite =
            0.3 + 0.7 * (valeur < 0.5 ? valeur * 2 : (1 - valeur) * 2);
        return Opacity(
          opacity: opacite,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
