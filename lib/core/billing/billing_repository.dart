import 'package:supabase_flutter/supabase_flutter.dart';

import '../entitlements/plan.dart';

/// Erreur de paiement présentable à l'utilisateur.
class BillingException implements Exception {
  const BillingException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Issue d'un démarrage de paiement.
enum CheckoutStatus {
  /// Paiement confirmé immédiatement (prestataire `mock`) — rien à ouvrir.
  paid,

  /// Paiement en cours : ouvrir [CheckoutSession.checkoutUrl].
  pending,
}

class CheckoutSession {
  const CheckoutSession({
    required this.status,
    required this.transactionId,
    required this.checkoutUrl,
  });

  final CheckoutStatus status;
  final String transactionId;
  final String checkoutUrl;

  factory CheckoutSession.fromJson(Map<String, dynamic> json) {
    return CheckoutSession(
      status: json['status'] == 'paid' ? CheckoutStatus.paid : CheckoutStatus.pending,
      transactionId: json['transactionId'] as String? ?? '',
      checkoutUrl: json['checkoutUrl'] as String? ?? '',
    );
  }
}

/// Frontière data vers le paiement d'un abonnement.
abstract class BillingRepository {
  Future<CheckoutSession> startCheckout(PlanCode plan);
}

/// Implémentation adossée à l'Edge Function `billing-checkout`
/// (voir `supabase/functions/`).
class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<CheckoutSession> startCheckout(PlanCode plan) async {
    try {
      final response = await client.functions.invoke(
        'billing-checkout',
        body: {'planCode': plan.name},
      );
      final data = response.data;
      if (data is! Map) {
        throw const BillingException('Réponse inattendue du service de paiement.');
      }
      return CheckoutSession.fromJson(data.cast<String, dynamic>());
    } on FunctionException catch (error) {
      final details = error.details;
      final message = details is Map ? details['error']?.toString() : null;
      throw BillingException(message ?? 'Le paiement n\'a pas pu être démarré.');
    }
  }
}

/// Utilisée quand Supabase n'est pas configuré : le paiement est indisponible.
class UnavailableBillingRepository implements BillingRepository {
  const UnavailableBillingRepository();

  @override
  Future<CheckoutSession> startCheckout(PlanCode plan) {
    throw const BillingException('Le paiement est indisponible (backend non configuré).');
  }
}
