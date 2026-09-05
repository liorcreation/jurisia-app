import '../supabase/supabase_config.dart';

/// Charge, pour une clé de [PromptKeys], le contenu publié dans
/// `ai_prompts` (voir migration_013_ai_prompts.sql) — jamais pour
/// REMPLACER un prompt système, toujours pour lui AJOUTER une consigne
/// éditoriale complémentaire en fin de prompt (voir [compose]). C'est le
/// choix le plus sûr : laisser un juriste réécrire en bloc un prompt qui
/// impose un protocole de sortie structurée (bloc JSON caché, dont dépend
/// par exemple la grille d'analyse de Litige ou les clauses à risque
/// d'Audit) romprait ce protocole sans qu'aucune erreur ne soit visible.
///
/// Repli gracieux total : Supabase indisponible, table pas encore migrée,
/// aucune ligne publiée pour cette clé → le prompt fixe s'utilise seul,
/// exactement comme avant l'existence du Studio de prompts. Résultat mis
/// en cache pour la durée de la session (un redémarrage de l'app recharge
/// la dernière version publiée).
class PromptOverrides {
  const PromptOverrides._();

  static final Map<String, String?> _cache = {};

  static Future<String?> _fetchAddendum(String key) async {
    if (_cache.containsKey(key)) return _cache[key];
    if (!SupabaseConfig.isReady) return null;
    try {
      final rows = await SupabaseConfig.client
          .from('ai_prompts')
          .select('content')
          .eq('key', key)
          .eq('status', 'published')
          .limit(1);
      final list = rows as List;
      final content = list.isEmpty ? null : (list.first as Map)['content'] as String?;
      _cache[key] = content;
      return content;
    } catch (_) {
      // Table pas encore migrée, réseau indisponible... on ne bloque jamais
      // la fonctionnalité principale pour un addendum éditorial.
      return null;
    }
  }

  /// Compose [basePrompt] (le prompt système fixe, avec son éventuel
  /// protocole de sortie) et l'addendum publié pour [key], s'il existe.
  static Future<String> compose(String key, String basePrompt) async {
    final addendum = await _fetchAddendum(key);
    if (addendum == null || addendum.trim().isEmpty) return basePrompt;
    return '$basePrompt\n\n'
        'Consignes éditoriales complémentaires (Studio de prompts, à '
        'respecter sans jamais modifier le format de sortie déjà spécifié '
        'ci-dessus) :\n'
        '${addendum.trim()}';
  }
}
