import 'package:flutter_test/flutter_test.dart';

import 'package:jurisia_app/features/student/data/datasources/training_catalog_local_datasource.dart';
import 'package:jurisia_app/features/student/domain/entities/training_certificate.dart';
import 'package:jurisia_app/models/training/training_category.dart';

void main() {
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

      expect(certifying, hasLength(5));
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
