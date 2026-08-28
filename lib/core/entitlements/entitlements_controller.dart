import 'package:flutter/foundation.dart';

import '../storage/local_cache.dart';
import 'entitlements_repository.dart';
import 'plan.dart';
import 'quota_state.dart';

/// État des droits d'accès de l'utilisateur : l'offre active et la
/// consommation des quotas du mois en cours.
///
/// Philosophie, cohérente avec le reste de l'application : **jamais bloquer
/// pour une raison d'infrastructure**. Le serveur (Supabase) est la source
/// de vérité quand il répond ; sinon, un compteur mensuel local applique le
/// quota de l'offre Découverte. Un échec réseau ne doit ni ouvrir les
/// vannes, ni verrouiller un utilisateur légitime.
class EntitlementsController extends ChangeNotifier {
  EntitlementsController({
    required this.repository,
    this.usageScope,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _plan = _readCachedPlan() ?? PlanCode.decouverte;
    // ignore: unawaited_futures
    refresh();
  }

  final EntitlementsRepository repository;

  /// Préfixe de cache propre à l'utilisateur connecté (`null` = pas de
  /// persistance locale ; la consommation n'est alors suivie qu'en mémoire
  /// pour la session).
  final String? usageScope;

  final DateTime Function() _now;

  static const String _planKeyPrefix = 'entitlements.plan.v1';
  static const String _usageKeyPrefix = 'entitlements.usage.v1';

  PlanCode _plan = PlanCode.decouverte;
  PlanCode get plan => _plan;

  PlanDefinition get definition => PlanCatalog.of(_plan);

  bool get isPremium => _plan != PlanCode.decouverte;

  /// Compteurs de consommation du mois en cours, tenus en mémoire et
  /// reflétés dans le cache local quand il est disponible.
  final Map<String, int> _usage = {};

  String get _period {
    final n = _now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  /// Recharge l'offre et la consommation depuis le serveur. Sans effet si le
  /// serveur ne répond pas — l'état local est conservé.
  Future<void> refresh() async {
    final snapshot = await repository.load();
    if (snapshot == null) return;

    var changed = false;

    if (snapshot.plan != _plan) {
      _plan = snapshot.plan;
      _writeCachedPlan(_plan);
      changed = true;
    }

    // Réconciliation : le serveur fait foi, mais on ne descend jamais un
    // compteur local sous sa valeur de session (un incrément fait ici ne
    // doit pas être « oublié » parce que le serveur ne l'a pas encore vu).
    snapshot.usage.forEach((feature, serverCount) {
      if (serverCount > _readUsage(feature)) {
        _writeUsage(feature, serverCount);
        changed = true;
      }
    });

    if (changed) notifyListeners();
  }

  /// Consommation du mois en cours pour une fonctionnalité.
  int usedThisMonth(String feature) => _readUsage(feature);

  /// État du quota d'une fonctionnalité pour l'offre active (pour les jauges
  /// de l'écran « Mon abonnement »).
  QuotaState quotaFor(String feature) {
    final quotas = definition.quotas;
    if (!quotas.containsKey(feature)) {
      return QuotaState(limit: 0, used: _readUsage(feature));
    }
    return QuotaState(limit: quotas[feature], used: _readUsage(feature));
  }

  /// `true` si la fonctionnalité est comprise dans l'offre active.
  bool allows(String feature) => definition.allows(feature);

  /// Tente de consommer une unité de [feature].
  ///
  /// Renvoie `true` si l'action peut se poursuivre (quota disponible,
  /// illimité, ou capacité incluse) ; `false` si le quota de l'offre est
  /// atteint — l'appelant affiche alors la feuille d'incitation à
  /// l'abonnement. Incrémente le compteur local et notifie le serveur au
  /// mieux effort quand l'action est autorisée.
  Future<bool> tryConsume(String feature) async {
    final quotas = definition.quotas;

    // Capacité booléenne : incluse dans l'offre, ou non.
    if (!quotas.containsKey(feature)) {
      return definition.capabilities.contains(feature);
    }

    final limit = quotas[feature]; // null => illimité
    final used = _readUsage(feature);
    if (limit != null && used >= limit) return false;

    _writeUsage(feature, used + 1);
    notifyListeners();
    // ignore: unawaited_futures
    repository.recordUsage(feature);
    return true;
  }

  // --- compteur local ----------------------------------------------------

  String _usageKey(String feature) => '$_usageKeyPrefix.$usageScope.$feature.$_period';

  int _readUsage(String feature) {
    final memo = _usage[feature];
    if (memo != null) return memo;

    final key = usageScope == null ? null : _usageKey(feature);
    final cache = LocalCache.instance;
    if (key == null || cache == null) return 0;

    final stored = cache.readJson<int>(key, (decoded) => decoded is int ? decoded : 0) ?? 0;
    _usage[feature] = stored;
    return stored;
  }

  void _writeUsage(String feature, int value) {
    _usage[feature] = value;
    final key = usageScope == null ? null : _usageKey(feature);
    final cache = LocalCache.instance;
    if (key == null || cache == null) return;
    // ignore: unawaited_futures
    cache.writeJson(key, value);
  }

  // --- cache de l'offre ------------------------------------------------

  String? get _planKey => usageScope == null ? null : '$_planKeyPrefix.$usageScope';

  PlanCode? _readCachedPlan() {
    final key = _planKey;
    final cache = LocalCache.instance;
    if (key == null || cache == null) return null;
    final name = cache.readJson<String?>(key, (decoded) => decoded is String ? decoded : null);
    return name == null ? null : PlanCodeName.fromName(name);
  }

  void _writeCachedPlan(PlanCode plan) {
    final key = _planKey;
    final cache = LocalCache.instance;
    if (key == null || cache == null) return;
    // ignore: unawaited_futures
    cache.writeJson(key, plan.name);
  }
}
