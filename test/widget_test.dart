import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/core/navigation/home_navigation.dart';
import 'package:jurisia_app/theme/app_theme.dart';

Widget _wrapHomeNavigation() {
  return MaterialApp(
    theme: AppTheme.darkTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.dark,
    home: const HomeNavigation(),
  );
}

/// La carte profil anime en continu (balayage doré du monogramme), donc
/// `pumpAndSettle` ne se stabilise jamais : on avance le temps par paliers.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  testWidgets('Narrow layout: the sidebar drawer carries the five spaces', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await _settle(tester);

    // Le premier espace (Litiges) est affiché, sans barre de navigation
    // inférieure — la navigation passe par le bouton hamburger.
    expect(find.text('Litiges et consultations'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    final menuButton = find.byIcon(Icons.menu_rounded);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await _settle(tester);

    for (final label in ['Litiges', 'Bibliothèque', 'Étudiant', 'Professionnel', 'Contacter']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Contacter'));
    await _settle(tester);
    expect(find.text('Contacter un professionnel'), findsWidgets);
    expect(find.text('Notaire'), findsOneWidget);
    expect(find.text('Juge'), findsOneWidget);
  });

  testWidgets('Wide layout: the permanent JurisIA sidebar renders without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await _settle(tester);

    expect(find.text('JurisIA'), findsOneWidget);
    for (final label in ['Litiges', 'Bibliothèque', 'Étudiant', 'Professionnel', 'Contacter']) {
      expect(find.text(label), findsOneWidget);
    }

    // Chaque espace rend sa section contextuelle dans la sidebar sans
    // exception ni débordement.
    for (final entry in const {
      'Bibliothèque': 'Bibliothèque juridique',
      'Étudiant': 'Espace étudiant',
      'Professionnel': 'Espace professionnel',
      'Contacter': 'Contacter un professionnel',
      'Litiges': 'Litiges et consultations',
    }.entries) {
      await tester.tap(find.text(entry.key));
      await _settle(tester);
      expect(find.text(entry.value), findsWidgets, reason: entry.key);
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });

  testWidgets('Wide layout: the profile card opens the profile sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await _settle(tester);

    await tester.tap(find.text('Mon compte'));
    await _settle(tester);

    expect(find.text('Nom complet'), findsWidgets);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
