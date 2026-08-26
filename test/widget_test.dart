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

void main() {
  testWidgets('HomeNavigation shows the five navigation destinations', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await tester.pumpAndSettle();

    expect(find.text('Litiges'), findsOneWidget);
    expect(find.text('Bibliothèque'), findsOneWidget);
    expect(find.text('Étudiant'), findsOneWidget);
    expect(find.text('Professionnel'), findsOneWidget);
    expect(find.text('Contacter'), findsOneWidget);

    expect(find.text('Litiges et consultations'), findsOneWidget);

    await tester.tap(find.text('Bibliothèque'));
    await tester.pumpAndSettle();
    expect(find.text('Bibliothèque juridique'), findsOneWidget);

    await tester.tap(find.text('Contacter'));
    await tester.pumpAndSettle();
    expect(find.text('Contacter un professionnel'), findsOneWidget);
    expect(find.text('Notaire'), findsOneWidget);
    expect(find.text('Avocat'), findsOneWidget);
    expect(find.text('Juriste'), findsOneWidget);
    expect(find.text('Huissier'), findsOneWidget);
    expect(find.text('Greffier'), findsOneWidget);
    expect(find.text('Juge'), findsOneWidget);
  });

  testWidgets('Wide layout shows the JurisIA side rail without overflow', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await tester.pumpAndSettle();

    expect(find.text('JurisIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Pas de test end-to-end pumpant JurisIAApp directement : avec un projet
  // Supabase réellement configuré par défaut, AuthGate a besoin que
  // Supabase.initialize() ait tourné (fait dans main(), jamais dans un test
  // de widget) avant de toucher SupabaseConfig.client. Tester le flux
  // d'authentification proprement demanderait d'injecter le SupabaseClient
  // plutôt que de le lire depuis un singleton global — hors scope ici.
}
