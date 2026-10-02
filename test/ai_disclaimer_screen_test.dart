import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/core/legal/ai_disclaimer_screen.dart';
import 'package:jurisia_app/theme/app_theme.dart';

void main() {
  testWidgets('la page des limites IA reste lisible sur mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.darkTheme, home: const AiDisclaimerScreen()),
    );
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Limites de l’IA'), findsOneWidget);
    expect(
      find.text('Ce n\'est pas un avis juridique engageant'),
      findsOneWidget,
    );
    expect(find.text('Aucune garantie de résultat'), findsOneWidget);
    expect(find.text('Vérifiez les informations sensibles'), findsOneWidget);
    expect(
      find.text('Vos échanges transitent par un prestataire tiers'),
      findsOneWidget,
    );
    expect(find.text('Un usage plus sûr, en trois gestes'), findsOneWidget);
    expect(find.text('J\'ai compris'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
