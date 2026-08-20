import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Icône ronde de l'assistant "Uni" dans la palette ENI.
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
          colors: [AppColors.primary, Colors.black],
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
