import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/student/data/datasources/training_catalog_local_datasource.dart';
import 'package:jurisia_app/features/student/presentation/screens/training_catalog_screen.dart';
import 'package:jurisia_app/features/student/domain/entities/training_certificate.dart';
import 'package:jurisia_app/models/training/training_category.dart';
import 'package:jurisia_app/theme/app_theme.dart';

void main() {
  testWidgets(
    'le choix du format précède les spécialités et le détail en ligne reste visible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const TrainingCatalogScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'écran de choix');

      expect(find.text('Débuter la formation en ligne'), findsOneWidget);
      expect(
        find.text('S’inscrire pour la formation en présentiel'),
        findsOneWidget,
      );
      expect(find.text('Droit de la famille'), findsNothing);

      await tester.ensureVisible(find.text('Voir les spécialités'));
      await tester.tap(find.text('Voir les spécialités'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'catalogue en ligne');

      expect(find.text('Formation en ligne'), findsOneWidget);
      expect(find.text('Droit de la famille'), findsOneWidget);
      await tester.ensureVisible(find.text('Droit de la famille'));
      await tester.tap(find.text('Droit de la famille'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'détail de spécialité');

      expect(
        find.text('Une spécialité pensée pour la pratique.'),
        findsOneWidget,
      );
      expect(find.text('Débuter la formation en ligne'), findsOneWidget);
    },
  );

  testWidgets('le parcours reste lisible et sans débordement sur mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const TrainingCatalogScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'choix mobile');
    expect(find.text('Débuter la formation en ligne'), findsOneWidget);
    expect(
      find.text('S’inscrire pour la formation en présentiel'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Voir les spécialités'));
    await tester.tap(find.text('Voir les spécialités'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'catalogue mobile');

    await tester.ensureVisible(find.text('Droit de la famille'));
    await tester.tap(find.text('Droit de la famille'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'spécialité mobile');
    expect(
      find.text('Une spécialité pensée pour la pratique.'),
      findsOneWidget,
    );
  });

  test(
    'le catalogue distingue les formations disponibles du LMD verrouillé',
    () {
      final categories = const TrainingCatalogLocalDataSource().getAll();
      final certifying = categories
          .where((category) => category.trainingType == TrainingType.certifying)
          .toList();
      final lmd = categories.singleWhere(
        (category) => category.trainingType == TrainingType.lmd,
      );

      expect(certifying, hasLength(21));
      expect(certifying.every((category) => category.isAvailable), isTrue);
      expect(lmd.isAvailable, isFalse);
    },
  );

  test('les modèles formation se lisent depuis les colonnes Supabase', () {
    final category = TrainingCategory.fromJson({
      'id': 'cert-droit-famille',
      'title': 'Droit de la famille',
      'description': 'Parcours certifiant',
      'training_type': 'certifying',
      'is_available': true,
      'domain': 'famille',
      'icon': 'family',
      'sort_order': 10,
    });
    final certificate = TrainingCertificate.fromJson({
      'id': 'certificate-1',
      'category_id': category.id,
      'title': category.title,
      'certificate_number': 'JUR-2026-0001',
      'verification_code': 'VERIFY-0001',
      'status': 'issued',
      'issued_at': '2026-09-13T10:00:00Z',
      'signature_hash': 'sha256:demo',
    });

    expect(category.trainingType, TrainingType.certifying);
    expect(category.isAvailable, isTrue);
    expect(certificate.status, TrainingCertificateStatus.issued);
    expect(certificate.issuedAt, isNotNull);
    expect(certificate.toDatabaseRow()['category_id'], category.id);
  });
}
