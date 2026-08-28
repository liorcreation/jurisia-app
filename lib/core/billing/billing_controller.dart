import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import '../entitlements/plan.dart';
import 'billing_repository.dart';

typedef LaunchUrlFn = Future<bool> Function(Uri url);

/// Pilote le choix d'une offre payante : démarre le paiement, ouvre la page
/// du prestataire, et rafraîchit les droits d'accès quand le paiement est
/// confirmé immédiatement (prestataire `mock`).
class BillingController extends ChangeNotifier {
  BillingController({
    required this.repository,
    required this.onActivated,
    LaunchUrlFn? launcher,
  }) : _launch = launcher ?? ((url) => launchUrl(url, webOnlyWindowName: '_self'));

  final BillingRepository repository;

  /// Rappelé après une activation immédiate — typiquement
  /// `EntitlementsController.refresh`.
  final Future<void> Function() onActivated;

  final LaunchUrlFn _launch;

  bool _busy = false;
  String? _error;
  String? _info;
  PlanCode? _pendingPlan;

  bool get isBusy => _busy;
  String? get error => _error;
  String? get info => _info;

  /// L'offre dont le paiement est en cours (pour n'afficher le spinner que
  /// sur la bonne carte).
  PlanCode? get pendingPlan => _pendingPlan;

  Future<void> choosePlan(PlanCode plan) async {
    if (_busy) return;
    _busy = true;
    _pendingPlan = plan;
    _error = null;
    _info = null;
    notifyListeners();

    try {
      final session = await repository.startCheckout(plan);
      if (session.status == CheckoutStatus.paid) {
        await onActivated();
        _info = 'Abonnement activé.';
      } else {
        final uri = Uri.tryParse(session.checkoutUrl);
        if (uri == null || !await _launch(uri)) {
          throw const BillingException('Impossible d\'ouvrir la page de paiement.');
        }
      }
    } catch (error) {
      _error = error is BillingException ? error.message : 'Le paiement a échoué. Réessayez.';
    } finally {
      _busy = false;
      _pendingPlan = null;
      notifyListeners();
    }
  }

  void clearMessages() {
    _error = null;
    _info = null;
    notifyListeners();
  }
}
