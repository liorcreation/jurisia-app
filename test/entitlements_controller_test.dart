import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/entitlements/entitlement_feature.dart';
import 'package:jurisia_app/core/entitlements/entitlements_controller.dart';
import 'package:jurisia_app/core/entitlements/entitlements_repository.dart';
import 'package:jurisia_app/core/entitlements/plan.dart';
import 'package:jurisia_app/core/storage/local_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeEntitlementsRepository implements EntitlementsRepository {
  _FakeEntitlementsRepository({this.snapshot});

  EntitlementsSnapshot? snapshot;
  final List<String> recorded = [];

  @override
  Future<EntitlementsSnapshot?> load() async => snapshot;

  @override
  Future<void> recordUsage(String feature) async => recorded.add(feature);
}

DateTime _fixedNow() => DateTime(2026, 8, 15);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

EntitlementsController _controller(
  _FakeEntitlementsRepository repository, {
  String? usageScope = 'u1',
}) {
  return EntitlementsController(
    repository: repository,
    usageScope: usageScope,
    now: _fixedNow,
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    LocalCache.debugOverrideInstance(null);
    await LocalCache.initialize();
  });

  tearDown(() => LocalCache.debugOverrideInstance(null));

  group('PlanCatalog', () {
    test('l\'offre gratuite plafonne les consultations à 3', () {
      expect(PlanCatalog.free.limitOf(EntitlementFeature.litigeConsultations), 3);
      expect(PlanCatalog.free.allows(EntitlementFeature.proEspace), isFalse);
    });

    test('JurisIA+ rend les consultations illimitées et débloque le mode approfondi', () {
      expect(PlanCatalog.plus.allows(EntitlementFeature.litigeConsultations), isTrue);
      expect(PlanCatalog.plus.isMetered(EntitlementFeature.litigeConsultations), isFalse);
      expect(PlanCatalog.plus.capabilities, contains(EntitlementFeature.litigeModeApprofondi));
    });

    test('every plan code resolves to a definition', () {
      for (final code in PlanCode.values) {
        expect(PlanCatalog.of(code).code, code);
      }
    });
  });

  group('EntitlementsController — quota de l\'offre gratuite', () {
    test('autorise 3 consultations puis bloque la 4e', () async {
      final controller = _controller(_FakeEntitlementsRepository());
      await _settle();

      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isFalse);

      expect(controller.usedThisMonth(EntitlementFeature.litigeConsultations), 3);
    });

    test('notifie le serveur au mieux effort à chaque consommation autorisée', () async {
      final repo = _FakeEntitlementsRepository();
      final controller = _controller(repo);
      await _settle();

      await controller.tryConsume(EntitlementFeature.litigeConsultations);
      await controller.tryConsume(EntitlementFeature.litigeConsultations);
      await _settle();

      expect(repo.recorded, hasLength(2));
      expect(repo.recorded.first, EntitlementFeature.litigeConsultations);
    });

    test('une capacité hors offre (Espace pro) est refusée', () async {
      final controller = _controller(_FakeEntitlementsRepository());
      await _settle();

      expect(await controller.tryConsume(EntitlementFeature.proEspace), isFalse);
    });
  });

  group('EntitlementsController — offre premium', () {
    test('JurisIA+ : consultations illimitées, jamais bloquées', () async {
      final repo = _FakeEntitlementsRepository(
        snapshot: const EntitlementsSnapshot(plan: PlanCode.plus),
      );
      final controller = _controller(repo);
      await _settle();

      expect(controller.plan, PlanCode.plus);
      expect(controller.isPremium, isTrue);

      for (var i = 0; i < 10; i++) {
        expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      }
      expect(controller.quotaFor(EntitlementFeature.litigeConsultations).isUnlimited, isTrue);
    });

    test('Pro débloque l\'Espace professionnel', () async {
      final controller = _controller(
        _FakeEntitlementsRepository(snapshot: const EntitlementsSnapshot(plan: PlanCode.pro)),
      );
      await _settle();

      expect(await controller.tryConsume(EntitlementFeature.proEspace), isTrue);
    });
  });

  group('EntitlementsController — compteur local & réconciliation', () {
    test('le compteur mensuel survit à un nouveau contrôleur (même utilisateur)', () async {
      final first = _controller(_FakeEntitlementsRepository());
      await _settle();
      await first.tryConsume(EntitlementFeature.litigeConsultations);
      await first.tryConsume(EntitlementFeature.litigeConsultations);
      await _settle();

      final second = _controller(_FakeEntitlementsRepository());
      expect(second.usedThisMonth(EntitlementFeature.litigeConsultations), 2);
      expect(await second.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await second.tryConsume(EntitlementFeature.litigeConsultations), isFalse);
    });

    test('le serveur relève le compteur local mais ne le fait jamais baisser', () async {
      // Compteur local à 1.
      final seed = _controller(_FakeEntitlementsRepository());
      await _settle();
      await seed.tryConsume(EntitlementFeature.litigeConsultations);
      await _settle();

      // Le serveur en connaît 2 (autre appareil) : on s'aligne sur 2.
      final higher = _controller(
        _FakeEntitlementsRepository(
          snapshot: const EntitlementsSnapshot(
            plan: PlanCode.decouverte,
            usage: {EntitlementFeature.litigeConsultations: 2},
          ),
        ),
      );
      await _settle();
      expect(higher.usedThisMonth(EntitlementFeature.litigeConsultations), 2);

      // Le serveur en renvoie 0 (retard de propagation) : on ne descend pas.
      final lower = _controller(
        _FakeEntitlementsRepository(
          snapshot: const EntitlementsSnapshot(
            plan: PlanCode.decouverte,
            usage: {EntitlementFeature.litigeConsultations: 0},
          ),
        ),
      );
      await _settle();
      expect(lower.usedThisMonth(EntitlementFeature.litigeConsultations), 2);
    });

    test('sans usageScope, le quota est tout de même appliqué pour la session', () async {
      final controller = _controller(_FakeEntitlementsRepository(), usageScope: null);
      await _settle();

      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isTrue);
      expect(await controller.tryConsume(EntitlementFeature.litigeConsultations), isFalse);
    });
  });
}
