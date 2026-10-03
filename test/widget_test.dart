import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:jurisia_app/core/navigation/home_navigation.dart';
import 'package:jurisia_app/core/widgets/chat_composer.dart';
import 'package:jurisia_app/core/widgets/glass_container.dart';
import 'package:jurisia_app/features/litigation/presentation/controllers/litigation_chat_controller.dart';
import 'package:jurisia_app/features/litigation/presentation/litigation_providers.dart';
import 'package:jurisia_app/features/litigation/presentation/screens/litigation_screen.dart';
import 'package:jurisia_app/theme/app_theme.dart';

Widget _wrapHomeNavigation({
  TargetPlatform platform = TargetPlatform.android,
  double textScale = 1,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme.copyWith(platform: platform),
    darkTheme: AppTheme.darkTheme.copyWith(platform: platform),
    themeMode: ThemeMode.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const HomeNavigation(),
  );
}

Widget _wrapLitigationScreen({
  required TargetPlatform platform,
  required double textScale,
}) {
  return MaterialApp(
    theme: AppTheme.darkTheme.copyWith(platform: platform),
    darkTheme: AppTheme.darkTheme.copyWith(platform: platform),
    themeMode: ThemeMode.dark,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: ChangeNotifierProvider<LitigationChatController>(
      create: (_) => buildLitigationChatController(),
      child: const LitigationScreen(),
    ),
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

    for (final label in [
      'Litiges',
      'Bibliothèque',
      'Étudiant',
      'Service professionnel',
      'Contacter',
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('Contacter'));
    await _settle(tester);
    expect(find.text('Contacter un professionnel'), findsWidgets);
    expect(find.text('Notaire'), findsOneWidget);
    expect(find.text('Juge'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await _settle(tester);
    expect(find.text('Consultations ce mois'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Litigation landing stays usable across phone sizes and text scaling',
    (WidgetTester tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const cases = [
        (Size(320, 568), TargetPlatform.android, 1.0),
        (Size(360, 640), TargetPlatform.android, 1.0),
        (Size(360, 800), TargetPlatform.android, 1.0),
        (Size(375, 667), TargetPlatform.iOS, 1.0),
        (Size(390, 844), TargetPlatform.iOS, 1.2),
        (Size(428, 926), TargetPlatform.iOS, 1.0),
        (Size(568, 320), TargetPlatform.iOS, 1.0),
        (Size(844, 390), TargetPlatform.android, 1.0),
        (Size(932, 430), TargetPlatform.iOS, 1.0),
      ];

      for (final (size, platform, textScale) in cases) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          _wrapLitigationScreen(platform: platform, textScale: textScale),
        );
        await _settle(tester);

        expect(
          find.text('Litiges et consultations'),
          findsOneWidget,
          reason: '$size / $platform',
        );
        expect(
          find.text('Quel est votre sujet ?'),
          findsOneWidget,
          reason: '$size / $platform',
        );

        // Le dernier domaine doit pouvoir défiler entièrement dans la zone de
        // lecture, sans être recouvert par le rappel IA ou le composeur fixe.
        final lastDomain = find.text('Autre situation');
        await tester.ensureVisible(lastDomain);
        await _settle(tester);
        final lastDomainCard = find
            .ancestor(of: lastDomain, matching: find.byType(GlassContainer))
            .first;
        expect(
          tester.getRect(lastDomainCard).bottom,
          lessThanOrEqualTo(tester.getRect(find.byType(ChatComposer)).top),
          reason:
              '$size / $platform / la carte doit rester au-dessus du composeur',
        );
        await tester.tap(lastDomain);
        await _settle(tester);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller?.text,
          'Je souhaite expliquer une situation juridique. ',
          reason: '$size / $platform / domaine actionnable',
        );
        expect(tester.takeException(), isNull, reason: '$size / $platform');
      }
    },
  );

  testWidgets('iPhone litigation title aligns with the navigation toolbar', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(428, 926);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation(platform: TargetPlatform.iOS));
    await _settle(tester);

    final title = find.text('Litiges et consultations');
    final menu = find.byIcon(Icons.menu_rounded);
    expect(title, findsOneWidget);
    expect(menu, findsOneWidget);
    expect(
      tester.getRect(title).center.dy,
      closeTo(tester.getRect(menu).center.dy, 2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Wide layout: the permanent JurisIA sidebar renders without overflow',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapHomeNavigation());
      await _settle(tester);

      expect(find.text('JurisIA'), findsOneWidget);
      for (final label in [
        'Litiges',
        'Bibliothèque',
        'Étudiant',
        'Service professionnel',
        'Contacter',
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      // Chaque espace rend sa section contextuelle dans la sidebar sans
      // exception ni débordement.
      for (final entry in const {
        'Bibliothèque': 'Bibliothèque juridique',
        'Étudiant': 'Espace étudiant',
        'Service professionnel': 'Service professionnel',
        'Contacter': 'Contacter un professionnel',
        'Litiges': 'Litiges et consultations',
      }.entries) {
        await tester.tap(find.text(entry.key));
        await _settle(tester);
        expect(find.text(entry.value), findsWidgets, reason: entry.key);
        if (entry.key == 'Service professionnel') {
          for (final category in [
            'Services notariaux',
            'Services d’avocats',
            'Services d’huissier',
            'Jurisconsulte',
          ]) {
            expect(find.text(category), findsOneWidget);
          }
        }
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    },
  );

  testWidgets('Wide layout: the profile card opens the profile sheet', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await _settle(tester);

    expect(find.text('Consultations ce mois'), findsOneWidget);
    expect(find.text('Découverte'), findsOneWidget);
    await tester.tap(find.text('Mon compte'));
    await _settle(tester);

    expect(find.text('Nom complet'), findsWidgets);
    expect(find.text('Se déconnecter'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Collapsed rail keeps the current space and profile reachable', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrapHomeNavigation());
    await _settle(tester);
    await tester.tap(find.byTooltip('Replier la navigation'));
    await _settle(tester);

    expect(find.byTooltip('Litiges'), findsOneWidget);
    expect(find.byTooltip('Mon compte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Library packs open cleanly on phone and desktop', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(400, 900), Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_wrapHomeNavigation());
      await _settle(tester);

      if (size.width < 600) {
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await _settle(tester);
      }
      await tester.tap(find.text('Bibliothèque'));
      await _settle(tester);

      expect(
        find.text('Le droit, organisé pour éclairer vos décisions.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'catalogue $size');

      await tester.ensureVisible(find.text('DROIT DES OBLIGATIONS'));
      await _settle(tester);
      await tester.tap(find.text('DROIT DES OBLIGATIONS'));
      await _settle(tester);
      expect(find.textContaining('COLLECTION'), findsOneWidget);
      expect(
        find.text('Obligations, contrats et responsabilité'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull, reason: 'pack $size');
    }
  });

  testWidgets('Student journey opens the catalogue and a specialty cleanly', (
    WidgetTester tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Le parcours complet est vérifié sur mobile ; la navigation desktop est
    // déjà couverte par le test de shell permanent ci-dessus.
    for (final size in const [Size(400, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_wrapHomeNavigation());
      await _settle(tester);

      if (size.width < 600) {
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await _settle(tester);
      }
      await tester.tap(find.text('Étudiant'));
      await _settle(tester);
      expect(find.textContaining('Votre progression'), findsOneWidget);

      await tester.ensureVisible(find.text('Formations Certifiantes'));
      await tester.tap(find.text('Formations Certifiantes'));
      await _settle(tester);
      expect(find.text('Choisissez votre spécialité.'), findsOneWidget);
      expect(
        tester.takeException(),
        isNull,
        reason: 'catalogue étudiant $size',
      );

      await tester.ensureVisible(find.text('Droit de la famille'));
      await tester.tap(find.text('Droit de la famille'));
      await _settle(tester);
      expect(
        find.text('Une spécialité pensée pour la pratique.'),
        findsOneWidget,
      );
      expect(find.text('Architecture du parcours'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'spécialité $size');
    }
  });

  testWidgets(
    'Tablet layout: a permanent compact rail preserves content space',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrapHomeNavigation());
      await _settle(tester);

      // La tablette garde un rail permanent ; le tiroir mobile et la barre
      // inférieure ne doivent pas revenir sur cette largeur intermédiaire.
      expect(find.byTooltip('Rechercher'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
