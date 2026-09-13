import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/core/widgets/premium_surface.dart';
import 'package:jurisia_app/theme/app_theme.dart';

void main() {
  test('Royal Legal Dark tokens stay aligned with the visual brief', () {
    expect(AppColors.deepSlate, const Color(0xFF0B0F19));
    expect(AppColors.cobalt, const Color(0xFF1E56A0));
    expect(AppColors.gold, const Color(0xFFD4AF37));
    expect(AppColors.textPrimary, const Color(0xFFF8FAFC));
    expect(AppMotion.standard, const Duration(milliseconds: 300));
    expect(AppBreakpoints.contentMaxWidth, 1200);
  });

  testWidgets('premium primitives render with accessible labels', (tester) async {
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
}
