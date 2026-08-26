import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/features/contact_professional/domain/entities/contact_request.dart';
import 'package:jurisia_app/features/contact_professional/domain/entities/professional_category.dart';
import 'package:jurisia_app/features/contact_professional/domain/repositories/contact_professional_repository.dart';
import 'package:jurisia_app/features/contact_professional/domain/usecases/submit_contact_request_usecase.dart';
import 'package:jurisia_app/features/contact_professional/presentation/controllers/contact_professional_controller.dart';

/// Fausse implémentation en mémoire, sans Supabase : suffisante pour tester
/// la validation du use case et la machine à états du contrôleur, qui ne
/// dépendent que de l'interface [ContactProfessionalRepository].
class _FakeContactProfessionalRepository implements ContactProfessionalRepository {
  final List<ContactRequest> _requests = [];
  bool shouldFail = false;
  var submitCallCount = 0;

  @override
  List<ContactRequest> get requests => List.unmodifiable(_requests);

  @override
  Future<void> hydrate() async {}

  @override
  Future<ContactRequest> submitRequest({
    required ProfessionalCategory category,
    required String fullName,
    required String contactInfo,
    required String message,
  }) async {
    submitCallCount++;
    if (shouldFail) {
      throw StateError('Vous devez être connecté pour envoyer une demande de contact.');
    }
    final request = ContactRequest(
      id: 'req-$submitCallCount',
      category: category,
      fullName: fullName,
      contactInfo: contactInfo,
      message: message,
      createdAt: DateTime(2026, 1, 1),
    );
    _requests.insert(0, request);
    return request;
  }
}

void main() {
  group('SubmitContactRequestUseCase', () {
    test('rejette un nom complet vide', () {
      final repository = _FakeContactProfessionalRepository();
      final useCase = SubmitContactRequestUseCase(repository: repository);

      expect(
        () => useCase(
          category: ProfessionalCategory.avocat,
          fullName: '   ',
          contactInfo: '70000000',
          message: 'Besoin de conseil',
        ),
        throwsArgumentError,
      );
      expect(repository.submitCallCount, 0);
    });

    test('rejette un moyen de contact vide', () {
      final repository = _FakeContactProfessionalRepository();
      final useCase = SubmitContactRequestUseCase(repository: repository);

      expect(
        () => useCase(
          category: ProfessionalCategory.notaire,
          fullName: 'Awa Traoré',
          contactInfo: '  ',
          message: 'Besoin de conseil',
        ),
        throwsArgumentError,
      );
    });

    test('rejette un message vide', () {
      final repository = _FakeContactProfessionalRepository();
      final useCase = SubmitContactRequestUseCase(repository: repository);

      expect(
        () => useCase(
          category: ProfessionalCategory.notaire,
          fullName: 'Awa Traoré',
          contactInfo: 'awa@example.com',
          message: '',
        ),
        throwsArgumentError,
      );
    });

    test('transmet une demande valide au repository, champs recadrés', () async {
      final repository = _FakeContactProfessionalRepository();
      final useCase = SubmitContactRequestUseCase(repository: repository);

      final result = await useCase(
        category: ProfessionalCategory.huissier,
        fullName: '  Awa Traoré  ',
        contactInfo: ' awa@example.com ',
        message: ' Signification urgente ',
      );

      expect(result.fullName, 'Awa Traoré');
      expect(result.contactInfo, 'awa@example.com');
      expect(result.message, 'Signification urgente');
      expect(result.category, ProfessionalCategory.huissier);
      expect(result.status, ContactRequestStatus.pending);
      expect(repository.requests, hasLength(1));
    });
  });

  group('ContactProfessionalController', () {
    test('passe par submitting puis success pour une demande valide', () async {
      final repository = _FakeContactProfessionalRepository();
      final controller = ContactProfessionalController(
        repository: repository,
        submitUseCase: SubmitContactRequestUseCase(repository: repository),
      );

      expect(controller.status, ContactSubmissionStatus.idle);

      final success = await controller.submit(
        category: ProfessionalCategory.juriste,
        fullName: 'Awa Traoré',
        contactInfo: '70000000',
        message: 'Question sur un bail commercial',
      );

      expect(success, isTrue);
      expect(controller.status, ContactSubmissionStatus.success);
      expect(controller.requests, hasLength(1));
    });

    test('passe à error et conserve un message quand le repository échoue', () async {
      final repository = _FakeContactProfessionalRepository()..shouldFail = true;
      final controller = ContactProfessionalController(
        repository: repository,
        submitUseCase: SubmitContactRequestUseCase(repository: repository),
      );

      final success = await controller.submit(
        category: ProfessionalCategory.juge,
        fullName: 'Awa Traoré',
        contactInfo: '70000000',
        message: 'Orientation de procédure',
      );

      expect(success, isFalse);
      expect(controller.status, ContactSubmissionStatus.error);
      expect(controller.errorMessage, isNotNull);
    });

    test('ne contacte pas le repository pour une demande invalide et remonte l\'erreur', () async {
      final repository = _FakeContactProfessionalRepository();
      final controller = ContactProfessionalController(
        repository: repository,
        submitUseCase: SubmitContactRequestUseCase(repository: repository),
      );

      final success = await controller.submit(
        category: ProfessionalCategory.greffier,
        fullName: '',
        contactInfo: '70000000',
        message: 'Dépôt de dossier',
      );

      expect(success, isFalse);
      expect(controller.status, ContactSubmissionStatus.error);
      expect(repository.submitCallCount, 0);
    });
  });

  group('ProfessionalCategory', () {
    test('seule la catégorie juge porte une mise en garde', () {
      for (final category in ProfessionalCategory.values) {
        if (category == ProfessionalCategory.juge) {
          expect(category.formNotice, isNotNull);
        } else {
          expect(category.formNotice, isNull);
        }
      }
    });

    test('fromName retombe sur juriste pour une valeur inconnue', () {
      expect(ProfessionalCategory.fromName('inconnu'), ProfessionalCategory.juriste);
      expect(ProfessionalCategory.fromName('avocat'), ProfessionalCategory.avocat);
    });
  });
}
