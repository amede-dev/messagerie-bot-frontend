import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// Bouton de réponse rapide affiché sous le dernier message du bot.
class QuickReplyChip extends StatelessWidget {
  final String texte;
  final VoidCallback onTap;

  const QuickReplyChip({super.key, required this.texte, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          texte,
          style: const TextStyle(fontSize: 12, color: AppColors.primary),
        ),
      ),
    );
  }
}
