/// Clés stables des prompts éditables depuis le Studio de prompts (console
/// d'admin, `lib/admin/features/prompt_studio/`) — voir
/// `server/supabase/migration_013_ai_prompts.sql`. Un contenu publié pour
/// une clé ne REMPLACE jamais le prompt système correspondant : il s'y
/// AJOUTE en fin de prompt, comme une consigne éditoriale complémentaire —
/// voir [PromptOverrides.compose] dans `prompt_overrides.dart`. Plusieurs
/// des prompts fixes imposent un protocole de sortie structurée (bloc JSON
/// caché) dont le reste de l'application dépend directement ; les rendre
/// librement remplaçables romprait ce protocole sans erreur visible.
class PromptKeys {
  const PromptKeys._();

  static const litige = 'litige.system';
  static const tuteur = 'tuteur.system';
  static const redaction = 'redaction.system';
  static const audit = 'audit.system';
  static const consultation = 'consultation.system';
}
