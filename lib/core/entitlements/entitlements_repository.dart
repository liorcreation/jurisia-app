import 'package:supabase_flutter/supabase_flutter.dart';

import 'plan.dart';

/// Instantané des droits d'accès renvoyé par le serveur : l'offre active et
/// la consommation du mois en cours, par fonctionnalité.
class EntitlementsSnapshot {
  const EntitlementsSnapshot({required this.plan, this.usage = const {}});

  final PlanCode plan;

  /// `feature -> nombre d'unités consommées ce mois-ci`.
  final Map<String, int> usage;
}

/// Frontière data vers la source des droits d'accès. Permet de substituer un
/// backend propriétaire à Supabase sans toucher au reste de l'architecture.
abstract class EntitlementsRepository {
  /// Charge l'offre active et la consommation du mois. Renvoie `null` en cas
  /// d'échec (réseau, migration non appliquée) : l'appelant reste alors en
  /// mode « compteur local » sans jamais bloquer l'utilisateur pour une
  /// raison d'infrastructure.
  Future<EntitlementsSnapshot?> load();

  /// Enregistre une unité de consommation d'une fonctionnalité, au mieux
  /// effort. Un échec est sans conséquence : le compteur local fait foi
  /// pendant la session.
  Future<void> recordUsage(String feature);
}

/// Repli utilisé quand Supabase n'est pas configuré (tests, développement
/// sans backend) : tout le monde est sur l'offre Découverte, la
/// consommation est suivie uniquement en local par le contrôleur.
class FreePlanEntitlementsRepository implements EntitlementsRepository {
  const FreePlanEntitlementsRepository();

  @override
  Future<EntitlementsSnapshot?> load() async {
    return const EntitlementsSnapshot(plan: PlanCode.decouverte);
  }

  @override
  Future<void> recordUsage(String feature) async {}
}

/// Implémentation adossée à Supabase.
///
/// Lectures / écritures au mieux effort : si les fonctions RPC ne sont pas
/// encore déployées (migration `007` non appliquée), [load] renvoie `null`
/// et [recordUsage] est silencieusement ignorée — le contrôleur applique
/// alors le quota Découverte depuis son compteur local. Le jour où la
/// migration est en place, le serveur redevient la source de vérité.
class SupabaseEntitlementsRepository implements EntitlementsRepository {
  SupabaseEntitlementsRepository({required this.client});

  final SupabaseClient client;

  @override
  Future<EntitlementsSnapshot?> load() async {
    try {
      final result = await client.rpc('jurisia_entitlements');
      if (result is! Map) return null;

      final planName = result['plan'] as String?;
      final rawUsage = result['usage'];
      final usage = <String, int>{};
      if (rawUsage is Map) {
        rawUsage.forEach((key, value) {
          final count = value is int ? value : int.tryParse('$value');
          if (count != null) usage['$key'] = count;
        });
      }

      return EntitlementsSnapshot(
        plan: PlanCodeName.fromName(planName),
        usage: usage,
      );
    } catch (error) {
      // ignore: avoid_print
      print('Chargement des droits d\'accès indisponible (repli compteur local) : $error');
      return null;
    }
  }

  @override
  Future<void> recordUsage(String feature) async {
    try {
      await client.rpc('jurisia_record_usage', params: {'p_feature': feature});
    } catch (error) {
      // ignore: avoid_print
      print('Enregistrement de la consommation « $feature » ignoré : $error');
    }
  }
}
