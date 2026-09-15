import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/admin/features/service_requests/admin_service_request_repository.dart';
import 'package:jurisia_app/admin/features/service_requests/admin_service_requests_controller.dart';
import 'package:jurisia_app/features/professional/domain/entities/professional_service_request.dart';
import 'package:jurisia_app/features/professional/domain/entities/professional_service_category.dart';

class _FakeAdminServiceRequestRepository
    implements AdminServiceRequestRepository {
  _FakeAdminServiceRequestRepository()
    : item = ProfessionalServiceRequest(
        id: 'service-1',
        kind: ProfessionalRequestKind.legalAct,
        category: ProfessionalServiceCategory.notarial,
        actType: 'Bail commercial',
        fullName: 'Awa Traoré',
        email: 'awa@example.com',
        phone: '70000000',
        details: 'Préparer un bail commercial.',
        urgency: ProfessionalRequestUrgency.standard,
        createdAt: DateTime(2026, 9, 13),
      );

  ProfessionalServiceRequest item;
  bool shouldFail = false;

  @override
  Future<List<ProfessionalServiceRequest>> list() async => [item];

  @override
  Future<ProfessionalServiceRequest> updateStatus({
    required String requestId,
    required ProfessionalServiceRequestStatus status,
    num? quoteAmount,
    String? quoteCurrency,
    String? depositUrl,
    String? dropoffLocation,
    String? pickupLocation,
  }) async {
    if (shouldFail) throw StateError('notification indisponible');
    item = item.copyWith(
      status: status,
      quoteAmount: quoteAmount,
      quoteCurrency: quoteCurrency,
      depositUrl: depositUrl,
      dropoffLocation: dropoffLocation,
      pickupLocation: pickupLocation,
    );
    return item;
  }
}

void main() {
  test('la console staff met à jour le devis et le statut', () async {
    final repository = _FakeAdminServiceRequestRepository();
    final controller = AdminServiceRequestsController(repository: repository);
    await controller.load();

    await controller.updateStatus(
      'service-1',
      ProfessionalServiceRequestStatus.quoteReady,
      quoteAmount: 125000,
      depositUrl: 'https://pay.example/1',
    );

    expect(
      controller.items.single.status,
      ProfessionalServiceRequestStatus.quoteReady,
    );
    expect(controller.items.single.quoteAmount, 125000);
    expect(controller.error, isNull);
  });

  test('la console conserve une erreur quand la notification échoue', () async {
    final repository = _FakeAdminServiceRequestRepository()..shouldFail = true;
    final controller = AdminServiceRequestsController(repository: repository);
    await controller.load();

    await controller.updateStatus(
      'service-1',
      ProfessionalServiceRequestStatus.acknowledged,
    );

    expect(controller.error, isNotNull);
    expect(
      controller.items.single.status,
      ProfessionalServiceRequestStatus.submitted,
    );
  });
}
