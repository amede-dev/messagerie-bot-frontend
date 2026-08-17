import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Icône ronde de l'assistant "Uni" : dégradé + symbole, dans l'esprit
/// des icônes d'assistants IA des messageries grand public, mais avec
/// une identité visuelle propre à l'application (bleu universitaire).
class UniLogo extends StatelessWidget {
  final double size;

  const UniLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6EA8FE), AppColors.primary, Color(0xFF17335C)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.48),
    );
  }
}
