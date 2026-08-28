import 'package:flutter/foundation.dart';

import '../../../features/contact_professional/domain/entities/contact_request.dart';
import 'admin_contact_request.dart';
import 'admin_contact_request_repository.dart';

/// État de l'écran « Demandes de mise en relation » : liste, filtre par
/// statut, et changement de statut avec mise à jour optimiste + rollback en
/// cas d'échec.
class AdminContactRequestsController extends ChangeNotifier {
  AdminContactRequestsController({required this.repository}) {
    // ignore: unawaited_futures
    load();
  }

  final AdminContactRequestRepository repository;

  List<AdminContactRequest> _items = const [];
  bool _loading = false;
  String? _error;
  ContactRequestStatus? _filter;
  final Set<String> _pending = {};

  bool get isLoading => _loading;
  String? get error => _error;
  ContactRequestStatus? get filter => _filter;

  List<AdminContactRequest> get items {
    if (_filter == null) return _items;
    return _items.where((item) => item.status == _filter).toList();
  }

  int countFor(ContactRequestStatus status) =>
      _items.where((item) => item.status == status).length;

  bool isUpdating(String id) => _pending.contains(id);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await repository.list();
    } catch (error) {
      _error = 'Chargement des demandes impossible. Vérifiez votre connexion et vos droits.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFilter(ContactRequestStatus? status) {
    _filter = status;
    notifyListeners();
  }

  Future<void> updateStatus(String id, ContactRequestStatus status) async {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1 || _pending.contains(id)) return;

    final previous = _items[index];
    if (previous.status == status) return;

    _pending.add(id);
    _items = [..._items]..[index] = previous.copyWith(status: status);
    notifyListeners();

    try {
      final updated = await repository.setStatus(id, status);
      final j = _items.indexWhere((item) => item.id == id);
      if (j != -1) _items = [..._items]..[j] = updated;
    } catch (error) {
      final j = _items.indexWhere((item) => item.id == id);
      if (j != -1) _items = [..._items]..[j] = previous;
      _error = 'Le statut n\'a pas pu être enregistré.';
    } finally {
      _pending.remove(id);
      notifyListeners();
    }
  }

  void dismissError() {
    _error = null;
    notifyListeners();
  }
}
