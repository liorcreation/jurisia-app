import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/core/widgets/premium_surface.dart';
import 'package:jurisia_app/core/widgets/entrance_fade.dart';
import 'package:jurisia_app/core/widgets/luxury_elevated_button.dart';
import 'package:jurisia_app/theme/app_theme.dart';

void main() {
  test('JurisIA night palette stays deep and high contrast', () {
    expect(AppColors.deepSlate, const Color(0xFF0B1220));
    expect(AppColors.cobalt, const Color(0xFF1D4C7D));
    expect(AppColors.cobaltDeep, const Color(0xFF0C2340));
    expect(AppColors.gold, const Color(0xFFD4AF37));
    expect(AppColors.textPrimary, const Color(0xFFF8FAFC));
    expect(AppGradients.smokedGlass.colors, const [
      Color(0xFF0C1A2B),
      Color(0xFF070D17),
    ]);
    expect(AppMotion.standard, const Duration(milliseconds: 300));
    expect(AppBreakpoints.contentMaxWidth, 1200);
    expect(AppPalette.primary[950], const Color(0xFF09182A));
    expect(AppPalette.accent[500], AppColors.gold);
    expect(AppPalette.neutral[50], const Color(0xFFF8FAFD));
    expect(AppSurfaces.lightSurface, Colors.white);
    expect(AppSurfaces.nightCanvas, AppColors.deepSlate);
    expect(AppTypeScale.body, 16);
  });

  testWidgets('entrance motion is skipped when reduced motion is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Scaffold(
            body: EntranceFadeSlide(child: Text('Contenu accessible')),
          ),
        ),
      ),
    );

    final fade = tester.widget<FadeTransition>(
      find.byType(FadeTransition).last,
    );
    expect(fade.opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('premium primitives render with accessible labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Column(
            children: [
              PremiumSectionHeader(
                eyebrow: 'Console',
                title: 'Vue d’ensemble',
                subtitle: 'Activité récente',
              ),
              PremiumStatusPill(
                label: 'Sécurisé',
                tone: PremiumStatusTone.success,
                icon: Icons.verified_rounded,
              ),
              PremiumMetricCard(
                icon: Icons.people_alt_rounded,
                label: 'Utilisateurs',
                value: '128',
                hint: '+12 ce mois',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Vue d’ensemble'), findsOneWidget);
    expect(find.text('Sécurisé'), findsOneWidget);
    expect(find.text('128'), findsOneWidget);
    expect(find.text('UTILISATEURS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary action exposes button semantics and remains tappable', (
    tester,
  ) async {
    var activated = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: LuxuryElevatedButton(
            onPressed: () => activated = true,
            child: const Text('Continuer'),
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(
        find
            .ancestor(
              of: find.byType(InkWell),
              matching: find.byType(Semantics),
            )
            .first,
      ),
      matchesSemantics(
        hasTapAction: true,
        hasFocusAction: true,
        isButton: true,
        isFocusable: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await tester.tap(find.byType(InkWell));
    expect(activated, isTrue);
  });
}
