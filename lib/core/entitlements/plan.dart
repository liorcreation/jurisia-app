import 'entitlement_feature.dart';

/// Les offres d'abonnement de JurisIA. Seule [PlanCode.decouverte] est
/// atteignable pour l'instant : le paiement (Mobile Money + carte) et la
/// bascule de palier arrivent dans un incrément ultérieur. Le catalogue est
/// néanmoins complet pour que l'écran « Mon abonnement » et la feuille
/// d'incitation soient réels dès maintenant.
enum PlanCode { decouverte, plus, etudiant, pro, cabinet }

extension PlanCodeName on PlanCode {
  static PlanCode fromName(String? value) {
    for (final code in PlanCode.values) {
      if (code.name == value) return code;
    }
    return PlanCode.decouverte;
  }
}

/// Définition d'une offre : identité commerciale + droits d'accès.
///
/// [quotas] : `feature -> plafond mensuel`. Une clé présente avec la valeur
/// `null` signifie « illimité » ; une clé absente signifie « fonctionnalité
/// hors de cette offre ». [capabilities] : fonctionnalités booléennes
/// débloquées (sans notion de quota).
class PlanDefinition {
  const PlanDefinition({
    required this.code,
    required this.name,
    required this.tagline,
    required this.priceLabel,
    required this.quotas,
    required this.capabilities,
    required this.highlights,
  });

  final PlanCode code;
  final String name;
  final String tagline;

  /// Prix indicatif affiché (« Gratuit », « 2 500 F CFA / mois »…). Les
  /// montants restent à valider par une étude de marché.
  final String priceLabel;

  final Map<String, int?> quotas;
  final Set<String> capabilities;

  /// Arguments mis en avant sur la carte de l'offre (texte libre).
  final List<String> highlights;

  bool get isFree => code == PlanCode.decouverte;

  /// `true` si l'offre s'achète en libre-service (par opposition à
  /// « Sur devis » comme JurisIA Cabinet).
  bool get isPurchasable => !isFree && code != PlanCode.cabinet;

  /// `true` si la fonctionnalité est comprise dans l'offre (quota fini,
  /// illimité, ou capacité booléenne).
  bool allows(String feature) => quotas.containsKey(feature) || capabilities.contains(feature);

  /// `true` si la fonctionnalité est un quota chiffré (par opposition à
  /// « illimité » ou à une capacité booléenne).
  bool isMetered(String feature) => quotas.containsKey(feature) && quotas[feature] != null;

  /// Plafond mensuel de la fonctionnalité, ou `null` si illimité / non
  /// métré.
  int? limitOf(String feature) => quotas[feature];
}

/// Catalogue compilé des offres. Source de vérité tant que Supabase n'expose
/// pas encore la table `plans` ; le client s'y réfère aussi en repli quand
/// le réseau est indisponible.
class PlanCatalog {
  const PlanCatalog._();

  static const PlanDefinition decouverte = PlanDefinition(
    code: PlanCode.decouverte,
    name: 'JurisIA Découverte',
    tagline: 'Pour explorer JurisIA librement.',
    priceLabel: 'Gratuit',
    quotas: {
      EntitlementFeature.litigeConsultations: 3,
      EntitlementFeature.contactRequests: 1,
    },
    capabilities: {},
    highlights: [
      '3 consultations « Litiges » par mois',
      'Bibliothèque juridique en lecture complète',
      'Espace étudiant — niveau L1',
      '1 demande de mise en relation par mois',
    ],
  );

  static const PlanDefinition plus = PlanDefinition(
    code: PlanCode.plus,
    name: 'JurisIA+',
    tagline: 'Pour aller au fond de chaque dossier.',
    priceLabel: '≈ 2 500 F CFA / mois',
    quotas: {
      EntitlementFeature.litigeConsultations: null,
      EntitlementFeature.contactRequests: null,
    },
    capabilities: {
      EntitlementFeature.litigeModeApprofondi,
      EntitlementFeature.litigeExportPdf,
      EntitlementFeature.iaPriorite,
      EntitlementFeature.coffreFort,
    },
    highlights: [
      'Consultations illimitées + historique complet',
      'Mode consultation approfondie',
      'Export PDF du dossier',
      'Priorité IA, sans plafond quotidien',
      'Demandes de mise en relation illimitées',
      'Coffre-fort de documents',
    ],
  );

  static const PlanDefinition etudiant = PlanDefinition(
    code: PlanCode.etudiant,
    name: 'JurisIA Étudiant',
    tagline: 'Tout le parcours, à prix étudiant.',
    priceLabel: '≈ 1 000 F CFA / mois',
    quotas: {
      EntitlementFeature.litigeConsultations: 3,
      EntitlementFeature.contactRequests: 1,
    },
    capabilities: {},
    highlights: [
      'Les 15 modules ouverts à l\'étude (L1 → M2)',
      'Évaluations et tuteur IA illimités',
      'Attestation de parcours',
      'Accès aux cas d\'école anonymisés',
    ],
  );

  static const PlanDefinition pro = PlanDefinition(
    code: PlanCode.pro,
    name: 'JurisIA Pro',
    tagline: 'L\'atelier juridique des praticiens.',
    priceLabel: '≈ 15 000 F CFA / mois',
    quotas: {
      EntitlementFeature.litigeConsultations: null,
      EntitlementFeature.contactRequests: null,
    },
    capabilities: {
      EntitlementFeature.litigeModeApprofondi,
      EntitlementFeature.litigeExportPdf,
      EntitlementFeature.iaPriorite,
      EntitlementFeature.coffreFort,
      EntitlementFeature.proEspace,
    },
    highlights: [
      'Espace professionnel entièrement débloqué',
      'Modèles d\'actes personnalisés + en-tête cabinet',
      'Audit de documents longs + comparaison de versions',
      'Base jurisprudence complète + veille juridique',
      'Priorité IA maximale',
      'Facturation entreprise (facture OHADA)',
    ],
  );

  static const PlanDefinition cabinet = PlanDefinition(
    code: PlanCode.cabinet,
    name: 'JurisIA Cabinet',
    tagline: 'Pour les cabinets et directions juridiques.',
    priceLabel: 'Sur devis',
    quotas: {
      EntitlementFeature.litigeConsultations: null,
      EntitlementFeature.contactRequests: null,
    },
    capabilities: {
      EntitlementFeature.litigeModeApprofondi,
      EntitlementFeature.litigeExportPdf,
      EntitlementFeature.iaPriorite,
      EntitlementFeature.coffreFort,
      EntitlementFeature.proEspace,
    },
    highlights: [
      'Sièges multiples + administration déléguée',
      'Partage de documents et dossiers clients',
      'SSO, SLA, DPA signé',
      'Bibliothèque de clauses privée + API',
    ],
  );

  /// Toutes les offres, dans l'ordre d'affichage.
  static const List<PlanDefinition> all = [decouverte, plus, etudiant, pro, cabinet];

  static PlanDefinition of(PlanCode code) {
    return all.firstWhere((plan) => plan.code == code, orElse: () => decouverte);
  }

  /// L'offre par défaut d'un compte sans abonnement actif.
  static const PlanDefinition free = decouverte;
}
