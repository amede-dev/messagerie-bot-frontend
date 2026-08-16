// This is a basic Flutter widget test for the Bot/Messagerie module (Gp6-5).
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:messagerie_bot/main.dart';

void main() {
  testWidgets('MessagerieApp se lance et affiche l\'écran des conversations', (
    WidgetTester tester,
  ) async {
    // MessagerieApp utilise Riverpod : il faut l'envelopper dans un ProviderScope,
    // comme c'est déjà fait dans main.dart via runApp(const ProviderScope(...)).
    await tester.pumpWidget(const ProviderScope(child: MessagerieApp()));

    // Un premier pump() suffit pour vérifier que l'app se construit sans erreur
    // (l'appel réseau de conversationListProvider reste en cours, donc on ne
    // fait pas de pumpAndSettle() qui attendrait indéfiniment une vraie réponse API).
    await tester.pump();

    // Vérifie que l'écran affiche bien le titre de la messagerie.
    expect(find.text('Messages'), findsOneWidget);

    // Vérifie que l'indicateur de chargement est affiché tant que les
    // conversations n'ont pas été récupérées depuis le backend.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
