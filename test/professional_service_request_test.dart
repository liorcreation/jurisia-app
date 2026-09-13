import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:jurisia_app/features/contact_professional/domain/entities/professional_category.dart';
import 'package:jurisia_app/features/professional/domain/entities/professional_service_request.dart';
import 'package:jurisia_app/features/professional/domain/repositories/professional_service_request_repository.dart';
import 'package:jurisia_app/features/professional/domain/usecases/submit_professional_service_request_usecase.dart';
import 'package:jurisia_app/features/professional/presentation/controllers/professional_service_request_controller.dart';
import 'package:jurisia_app/features/professional/presentation/widgets/professional_service_request_wizard.dart';
import 'package:jurisia_app/theme/app_theme.dart';

class _FakeProfessionalServiceRequestRepository
    implements ProfessionalServiceRequestRepository {
  final List<ProfessionalServiceRequest> _requests = [];
  var submitCallCount = 0;
  bool shouldFail = false;

  @override
  List<ProfessionalServiceRequest> get requests => List.unmodifiable(_requests);

  @override
  Future<void> hydrate() async {}

  @override
  Future<ProfessionalServiceRequest> submitRequest({
    required ProfessionalRequestKind kind,
    required String category,
    required String? actType,
    required String fullName,
    required String email,
    required String phone,
    required String details,
    required ProfessionalRequestUrgency urgency,
    required List<String> attachmentNames,
    required DateTime? desiredDate,
    required ProfessionalAppointmentMode? appointmentMode,
  }) async {
    submitCallCount++;
    if (shouldFail) throw StateError('service indisponible');
    final request = ProfessionalServiceRequest(
      id: 'service-$submitCallCount',
      kind: kind,
      category: ProfessionalCategory.fromName(category),
      actType: actType,
      fullName: fullName,
      email: email,
      phone: phone,
      details: details,
      urgency: urgency,
      attachmentNames: attachmentNames,
      desiredDate: desiredDate,
      appointmentMode: appointmentMode,
      createdAt: DateTime(2026, 9, 13),
    );
    _requests.insert(0, request);
    return request;
  }
}

void main() {
  group('SubmitProfessionalServiceRequestUseCase', () {
    test('valide et normalise une demande d’acte', () async {
      final repository = _FakeProfessionalServiceRequestRepository();
      final useCase = SubmitProfessionalServiceRequestUseCase(
        repository: repository,
      );

      final result = await useCase(
        kind: ProfessionalRequestKind.legalAct,
        category: 'notaire',
        actType: '  Statuts de société  ',
        fullName: ' Awa Traoré ',
        email: ' awa@example.com ',
        phone: '70000000',
        details: 'Création d’une société avec deux associés.',
        urgency: ProfessionalRequestUrgency.priority,
        attachmentNames: const ['CNI', 'projet'],
        desiredDate: null,
        appointmentMode: null,
      );

      expect(result.actType, 'Statuts de société');
      expect(result.fullName, 'Awa Traoré');
      expect(result.email, 'awa@example.com');
      expect(repository.submitCallCount, 1);
    });

    test('exige une date pour un rendez-vous expert', () {
      final useCase = SubmitProfessionalServiceRequestUseCase(
        repository: _FakeProfessionalServiceRequestRepository(),
      );

      expect(
        () => useCase(
          kind: ProfessionalRequestKind.expertAppointment,
          category: 'avocat',
          actType: null,
          fullName: 'Awa Traoré',
          email: 'awa@example.com',
          phone: '70000000',
          details: 'Échanger sur une stratégie de défense.',
          urgency: ProfessionalRequestUrgency.standard,
          attachmentNames: const [],
          desiredDate: null,
          appointmentMode: ProfessionalAppointmentMode.video,
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProfessionalServiceRequestController', () {
    test('passe de submitting à success et conserve l’historique', () async {
      final repository = _FakeProfessionalServiceRequestRepository();
      final controller = ProfessionalServiceRequestController(
        repository: repository,
        submitUseCase: SubmitProfessionalServiceRequestUseCase(
          repository: repository,
        ),
      );

      final success = await controller.submit(
        kind: ProfessionalRequestKind.expertAppointment,
        category: 'juriste',
        actType: null,
        fullName: 'Awa Traoré',
        email: 'awa@example.com',
        phone: '70000000',
        details: 'Relire une convention de prestation avant signature.',
        urgency: ProfessionalRequestUrgency.standard,
        attachmentNames: const [],
        desiredDate: DateTime(2026, 9, 20),
        appointmentMode: ProfessionalAppointmentMode.video,
      );

      expect(success, isTrue);
      expect(controller.status, ProfessionalRequestSubmissionStatus.success);
      expect(controller.requests, hasLength(1));
    });

    test('expose une erreur quand la persistance échoue', () async {
      final repository = _FakeProfessionalServiceRequestRepository()
        ..shouldFail = true;
      final controller = ProfessionalServiceRequestController(
        repository: repository,
        submitUseCase: SubmitProfessionalServiceRequestUseCase(
          repository: repository,
        ),
      );

      final success = await controller.submit(
        kind: ProfessionalRequestKind.legalAct,
        category: 'juriste',
        actType: 'Bail commercial',
        fullName: 'Awa Traoré',
        email: 'awa@example.com',
        phone: '70000000',
        details: 'Préparer un bail commercial pour une nouvelle activité.',
        urgency: ProfessionalRequestUrgency.standard,
        attachmentNames: const [],
        desiredDate: null,
        appointmentMode: null,
      );

      expect(success, isFalse);
      expect(controller.status, ProfessionalRequestSubmissionStatus.error);
      expect(controller.errorMessage, 'service indisponible');
    });
  });

  testWidgets('le wizard premium reste utilisable sur une largeur mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _FakeProfessionalServiceRequestRepository();
    final controller = ProfessionalServiceRequestController(
      repository: repository,
      submitUseCase: SubmitProfessionalServiceRequestUseCase(
        repository: repository,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<ProfessionalServiceRequestController>.value(
        value: controller,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: SafeArea(child: ProfessionalServiceRequestWizard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quel accompagnement recherchez-vous ?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
