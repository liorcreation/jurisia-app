import 'package:flutter/foundation.dart';

import '../../../features/professional/domain/entities/professional_service_request.dart';
import 'admin_service_request_repository.dart';

class AdminServiceRequestsController extends ChangeNotifier {
  AdminServiceRequestsController({required this.repository}) {
    load();
  }

  final AdminServiceRequestRepository repository;
  List<ProfessionalServiceRequest> _all = const [];
  ProfessionalServiceRequestStatus? _filter;
  final Set<String> _updating = {};
  bool _isLoading = true;
  String? _error;

  List<ProfessionalServiceRequest> get items => _filter == null
      ? List.unmodifiable(_all)
      : List.unmodifiable(_all.where((item) => item.status == _filter));
  ProfessionalServiceRequestStatus? get filter => _filter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int countFor(ProfessionalServiceRequestStatus status) =>
      _all.where((item) => item.status == status).length;

  bool isUpdating(String id) => _updating.contains(id);

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _all = await repository.list();
    } catch (_) {
      _error = 'Impossible de charger les demandes professionnelles.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(ProfessionalServiceRequestStatus? status) {
    _filter = status;
    notifyListeners();
  }

  Future<void> updateStatus(
    String id,
    ProfessionalServiceRequestStatus status, {
    num? quoteAmount,
    String? quoteCurrency,
    String? depositUrl,
    String? dropoffLocation,
    String? pickupLocation,
  }) async {
    if (!_updating.add(id)) return;
    _error = null;
    notifyListeners();
    try {
      final updated = await repository.updateStatus(
        requestId: id,
        status: status,
        quoteAmount: quoteAmount,
        quoteCurrency: quoteCurrency,
        depositUrl: depositUrl,
        dropoffLocation: dropoffLocation,
        pickupLocation: pickupLocation,
      );
      final index = _all.indexWhere((item) => item.id == id);
      if (index != -1) _all[index] = updated;
    } catch (_) {
      _error = 'La mise à jour et la notification n’ont pas abouti.';
    } finally {
      _updating.remove(id);
      notifyListeners();
    }
  }

  void dismissError() {
    _error = null;
    notifyListeners();
  }
}
