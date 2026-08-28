import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/admin/features/contact_requests/admin_contact_request.dart';
import 'package:jurisia_app/admin/features/contact_requests/admin_contact_request_repository.dart';
import 'package:jurisia_app/admin/features/contact_requests/admin_contact_requests_controller.dart';
import 'package:jurisia_app/features/contact_professional/domain/entities/contact_request.dart';
import 'package:jurisia_app/features/contact_professional/domain/entities/professional_category.dart';

AdminContactRequest _request(String id, ContactRequestStatus status) {
  return AdminContactRequest(
    id: id,
    userId: 'user-$id',
    category: ProfessionalCategory.avocat,
    fullName: 'Awa $id',
    contactInfo: '+226 70 00 00 0$id',
    message: 'Besoin d\'un avocat.',
    status: status,
    createdAt: DateTime(2026, 8, 1),
  );
}

class _FakeRepo implements AdminContactRequestRepository {
  _FakeRepo(this._items);

  List<AdminContactRequest> _items;
  bool failSetStatus = false;
  final List<String> statusCalls = [];

  @override
  Future<List<AdminContactRequest>> list() async => List.of(_items);

  @override
  Future<AdminContactRequest> setStatus(
    String id,
    ContactRequestStatus status, {
    String? reason,
  }) async {
    statusCalls.add('$id:${status.name}');
    if (failSetStatus) throw Exception('réseau');
    final updated = _items.firstWhere((r) => r.id == id).copyWith(status: status);
    _items = [
      for (final r in _items)
        if (r.id == id) updated else r,
    ];
    return updated;
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('load remplit la liste', () async {
    final controller = AdminContactRequestsController(
      repository: _FakeRepo([
        _request('1', ContactRequestStatus.pending),
        _request('2', ContactRequestStatus.contacted),
      ]),
    );
    await _settle();

    expect(controller.items, hasLength(2));
    expect(controller.countFor(ContactRequestStatus.pending), 1);
    expect(controller.error, isNull);
  });

  test('setFilter ne montre que le statut choisi', () async {
    final controller = AdminContactRequestsController(
      repository: _FakeRepo([
        _request('1', ContactRequestStatus.pending),
        _request('2', ContactRequestStatus.closed),
      ]),
    );
    await _settle();

    controller.setFilter(ContactRequestStatus.closed);
    expect(controller.items, hasLength(1));
    expect(controller.items.single.id, '2');
  });

  test('updateStatus applique le changement (optimiste puis confirmé)', () async {
    final repo = _FakeRepo([_request('1', ContactRequestStatus.pending)]);
    final controller = AdminContactRequestsController(repository: repo);
    await _settle();

    await controller.updateStatus('1', ContactRequestStatus.contacted);

    expect(controller.items.single.status, ContactRequestStatus.contacted);
    expect(repo.statusCalls, ['1:contacted']);
    expect(controller.error, isNull);
  });

  test('updateStatus revient en arrière et signale l\'erreur si le serveur échoue', () async {
    final repo = _FakeRepo([_request('1', ContactRequestStatus.pending)])..failSetStatus = true;
    final controller = AdminContactRequestsController(repository: repo);
    await _settle();

    await controller.updateStatus('1', ContactRequestStatus.closed);

    expect(controller.items.single.status, ContactRequestStatus.pending, reason: 'rollback');
    expect(controller.error, isNotNull);
  });
}
