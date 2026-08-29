import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:messagerie_bot/main.dart';

void main() {
  testWidgets('MessagerieApp se lance et affiche l\'écran des conversations', (
    WidgetTester tester,
  ) async {
 
    await tester.pumpWidget(const ProviderScope(child: MessagerieApp()));

    // Un premier pump() suffit pour vérifier que l'app se construit sans erreur
  
    await tester.pump();

    // Vérifie que l'écran affiche bien le titre de la messagerie.
    expect(find.text('Messages'), findsOneWidget);

    // Vérifie que l'indicateur de chargement est affiché tant que les
    // conversations n'ont pas été récupérées depuis le backend.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
