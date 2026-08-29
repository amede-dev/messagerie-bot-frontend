import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

// Écran "Médias partagés" — accessible depuis les paramètres d'une conversation.
class SharedMediaScreen extends StatelessWidget {
  final String conversationNom;

  const SharedMediaScreen({super.key, required this.conversationNom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Médias · $conversationNom')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_outlined, size: 48, color: AppColors.textMuted),
              SizedBox(height: 12),
              Text(
                'Aucun média partagé pour l\'instant',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
