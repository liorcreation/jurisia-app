import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/billing/billing_controller.dart';
import 'package:jurisia_app/core/billing/billing_repository.dart';
import 'package:jurisia_app/core/entitlements/plan.dart';

class _FakeBillingRepository implements BillingRepository {
  _FakeBillingRepository(this._result);

  final CheckoutSession? _result;
  Object? error;
  int calls = 0;

  @override
  Future<CheckoutSession> startCheckout(PlanCode plan) async {
    calls++;
    if (error != null) throw error!;
    return _result!;
  }
}

void main() {
  CheckoutSession paid() => const CheckoutSession(
        status: CheckoutStatus.paid,
        transactionId: 'tx1',
        checkoutUrl: 'https://app/billing-return?tx=tx1&mock=1',
      );

  CheckoutSession pending(String url) =>
      CheckoutSession(status: CheckoutStatus.pending, transactionId: 'tx2', checkoutUrl: url);

  test('paiement confirmé immédiatement : rafraîchit les droits, aucun lien ouvert', () async {
    var activated = 0;
    var launched = 0;
    final controller = BillingController(
      repository: _FakeBillingRepository(paid()),
      onActivated: () async => activated++,
      launcher: (_) async {
        launched++;
        return true;
      },
    );

    await controller.choosePlan(PlanCode.plus);

    expect(activated, 1);
    expect(launched, 0);
    expect(controller.info, isNotNull);
    expect(controller.error, isNull);
    expect(controller.isBusy, isFalse);
  });

  test('paiement en cours : ouvre l\'URL du prestataire', () async {
    Uri? opened;
    final controller = BillingController(
      repository: _FakeBillingRepository(pending('https://pay.example/abc')),
      onActivated: () async {},
      launcher: (url) async {
        opened = url;
        return true;
      },
    );

    await controller.choosePlan(PlanCode.pro);

    expect(opened.toString(), 'https://pay.example/abc');
    expect(controller.error, isNull);
  });

  test('échec d\'ouverture du lien : erreur présentable', () async {
    final controller = BillingController(
      repository: _FakeBillingRepository(pending('https://pay.example/abc')),
      onActivated: () async {},
      launcher: (_) async => false,
    );

    await controller.choosePlan(PlanCode.pro);

    expect(controller.error, contains('page de paiement'));
  });

  test('erreur du dépôt : message transmis tel quel', () async {
    final repo = _FakeBillingRepository(null)..error = const BillingException('Fonds insuffisants.');
    final controller = BillingController(
      repository: repo,
      onActivated: () async {},
      launcher: (_) async => true,
    );

    await controller.choosePlan(PlanCode.plus);

    expect(controller.error, 'Fonds insuffisants.');
  });

  test('un second appel est ignoré tant que le premier est en cours', () async {
    final repo = _FakeBillingRepository(paid());
    final controller = BillingController(
      repository: repo,
      onActivated: () async => Future<void>.delayed(const Duration(milliseconds: 30)),
      launcher: (_) async => true,
    );

    final first = controller.choosePlan(PlanCode.plus);
    await controller.choosePlan(PlanCode.pro); // ignoré : _busy
    await first;

    expect(repo.calls, 1);
  });
}
