/// Clés des fonctionnalités soumises à un droit d'accès (quota ou capacité).
///
/// Ces chaînes sont le contrat partagé entre le client, le cache local et —
/// à terme — les tables `plans` / `usage_events` de Supabase (voir
/// `server/supabase/migration_007_subscriptions_and_usage.sql`). Ne jamais
/// renommer une clé sans migration : elle sert d'identifiant de compteur.
class EntitlementFeature {
  const EntitlementFeature._();

  /// Nombre de consultations « Litiges » ouvertes dans le mois (quota).
  static const String litigeConsultations = 'litige.consultations';

  /// Mode « consultation approfondie » — plus de contexte, plafond de
  /// jetons plus élevé (capacité).
  static const String litigeModeApprofondi = 'litige.mode_approfondi';

  /// Export PDF d'une consultation en « dossier » (capacité).
  static const String litigeExportPdf = 'litige.export_pdf';

  /// File d'attente IA prioritaire (capacité).
  static const String iaPriorite = 'ia.priorite';

  /// Nombre de demandes de mise en relation envoyées dans le mois (quota).
  static const String contactRequests = 'contact.requests';

  /// Accès à l'Espace professionnel (rédaction / audit / consultation)
  /// (capacité).
  static const String proEspace = 'pro.espace';

  /// Coffre-fort de documents (capacité).
  static const String coffreFort = 'coffre_fort';

  /// Libellé lisible d'une fonctionnalité, pour les jauges d'usage et la
  /// feuille d'incitation à l'abonnement.
  static String label(String feature) {
    switch (feature) {
      case litigeConsultations:
        return 'Consultations juridiques';
      case litigeModeApprofondi:
        return 'Consultation approfondie';
      case litigeExportPdf:
        return 'Export PDF du dossier';
      case iaPriorite:
        return 'Priorité IA';
      case contactRequests:
        return 'Demandes de mise en relation';
      case proEspace:
        return 'Espace professionnel';
      case coffreFort:
        return 'Coffre-fort de documents';
      default:
        return feature;
    }
  }
}
