import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/core/widgets/splash_screen.dart';
import 'package:jurisia_app/features/auth/presentation/screens/auth_screen.dart';
import 'package:jurisia_app/theme/app_theme.dart';

Widget _app({required Widget home}) => MaterialApp(
  theme: AppTheme.darkTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.dark,
  home: home,
);

void main() {
  testWidgets('splash presents the JurisIA brand and legal scope', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(home: const JurisIASplashScreen(child: AuthScreen())),
    );
    expect(find.byType(JurisIASplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));

    expect(find.text('JurisIA'), findsOneWidget);
    expect(find.text('DROIT BURKINABÈ  ·  ESPACE OHADA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('email journey opens sign-in and switches to registration', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_app(home: const AuthScreen()));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.text('Se connecter ou s\'inscrire'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Content de vous revoir'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    await tester.tap(find.text('Créer un compte'));
    await tester.pump(const Duration(milliseconds: 260));

    expect(find.text('Rejoignez JurisIA'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.text('Vous êtes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wide sign-in threshold keeps the brand panel and actions balanced',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_app(home: const AuthScreen()));
      await tester.pump(const Duration(milliseconds: 80));

      expect(find.text('JurisIA'), findsOneWidget);
      expect(find.text('BURKINA FASO  ·  ESPACE OHADA'), findsOneWidget);
      expect(find.text('UN ACCÈS, TOUS VOS ESPACES'), findsOneWidget);
      expect(find.text('Continuer avec Google'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
