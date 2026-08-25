import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/core/navigation/home_navigation.dart';
import 'package:jurisia_app/main.dart';
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
  testWidgets('HomeNavigation shows the four navigation destinations', (
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

    expect(find.text('Litiges et consultations'), findsOneWidget);

    await tester.tap(find.text('Bibliothèque'));
    await tester.pumpAndSettle();
    expect(find.text('Bibliothèque juridique'), findsOneWidget);
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

  testWidgets('App shows the auth screen when no Supabase project is configured', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const JurisIAApp());
    await tester.pumpAndSettle();

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.textContaining('Aucun projet Supabase configuré'), findsOneWidget);
    expect(find.text('Litiges'), findsNothing);
  });
}
