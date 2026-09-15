import 'package:flutter/material.dart';

/// Typologie métier utilisée par le parcours « Services professionnels ».
///
/// Elle est volontairement distincte de [ProfessionalCategory], qui décrit
/// les professions proposées dans l'espace « Contacter ». Cela évite de
/// mélanger une demande de service (ex. création d'une coopérative) avec une
/// demande de mise en relation (ex. contacter un avocat).
enum ProfessionalServiceCategory {
  notarial,
  lawyers,
  bailiffs,
  jurisconsult,
  businessAndAssociation,
  companies,
  cooperatives,
  deepConsultation;

  static ProfessionalServiceCategory fromName(String? name) {
    final normalized = name?.trim().toLowerCase();
    return values.firstWhere(
      (value) => value.slug == normalized || value.name == normalized,
      orElse: () => switch (normalized) {
        'notaire' => notarial,
        'avocat' => lawyers,
        'huissier' => bailiffs,
        'juriste' => jurisconsult,
        _ => jurisconsult,
      },
    );
  }
}

extension ProfessionalServiceCategoryDetails on ProfessionalServiceCategory {
  String get slug => switch (this) {
    ProfessionalServiceCategory.notarial => 'services_notariaux',
    ProfessionalServiceCategory.lawyers => 'services_avocats',
    ProfessionalServiceCategory.bailiffs => 'services_huissier',
    ProfessionalServiceCategory.jurisconsult => 'jurisconsulte',
    ProfessionalServiceCategory.businessAndAssociation =>
      'creation_entreprise_association',
    ProfessionalServiceCategory.companies => 'creation_societes',
    ProfessionalServiceCategory.cooperatives => 'creation_cooperatives',
    ProfessionalServiceCategory.deepConsultation => 'consultation_approfondie',
  };

  String get label => switch (this) {
    ProfessionalServiceCategory.notarial => 'Services notariaux',
    ProfessionalServiceCategory.lawyers => 'Services d’avocats',
    ProfessionalServiceCategory.bailiffs => 'Services d’huissier',
    ProfessionalServiceCategory.jurisconsult => 'Jurisconsulte',
    ProfessionalServiceCategory.businessAndAssociation =>
      'Création d’entreprise et d’association',
    ProfessionalServiceCategory.companies => 'Création de sociétés',
    ProfessionalServiceCategory.cooperatives => 'Création de coopératives',
    ProfessionalServiceCategory.deepConsultation => 'Consultation approfondie',
  };

  String get description => switch (this) {
    ProfessionalServiceCategory.notarial =>
      'Actes authentiques, successions, immobilier et formalités notariales.',
    ProfessionalServiceCategory.lawyers =>
      'Conseil, contrats, défense et stratégie avec un avocat partenaire.',
    ProfessionalServiceCategory.bailiffs =>
      'Constats, significations, recouvrement et exécution des décisions.',
    ProfessionalServiceCategory.jurisconsult =>
      'Avis juridique, analyse de dossier et sécurisation de vos décisions.',
    ProfessionalServiceCategory.businessAndAssociation =>
      'Lancez une activité ou une association sur des bases solides.',
    ProfessionalServiceCategory.companies =>
      'Choisissez la forme sociale et préparez les actes de constitution.',
    ProfessionalServiceCategory.cooperatives =>
      'Statuts, gouvernance et formalités propres aux projets coopératifs.',
    ProfessionalServiceCategory.deepConsultation =>
      'Un échange structuré pour les dossiers complexes ou sensibles.',
  };

  IconData get icon => switch (this) {
    ProfessionalServiceCategory.notarial => Icons.account_balance_rounded,
    ProfessionalServiceCategory.lawyers => Icons.gavel_rounded,
    ProfessionalServiceCategory.bailiffs => Icons.markunread_mailbox_rounded,
    ProfessionalServiceCategory.jurisconsult => Icons.balance_rounded,
    ProfessionalServiceCategory.businessAndAssociation =>
      Icons.rocket_launch_rounded,
    ProfessionalServiceCategory.companies => Icons.business_center_rounded,
    ProfessionalServiceCategory.cooperatives => Icons.groups_rounded,
    ProfessionalServiceCategory.deepConsultation => Icons.psychology_rounded,
  };

  List<String> get serviceTypes => switch (this) {
    ProfessionalServiceCategory.notarial => const [
      'Acte authentique',
      'Succession ou donation',
      'Immobilier et foncier',
      'Statuts et formalités notariales',
    ],
    ProfessionalServiceCategory.lawyers => const [
      'Conseil juridique',
      'Rédaction ou revue de contrat',
      'Défense et représentation',
      'Stratégie précontentieuse',
    ],
    ProfessionalServiceCategory.bailiffs => const [
      'Signification d’un acte',
      'Constat',
      'Recouvrement',
      'Exécution d’une décision',
    ],
    ProfessionalServiceCategory.jurisconsult => const [
      'Avis juridique',
      'Note de consultation',
      'Veille et conformité',
      'Analyse stratégique',
    ],
    ProfessionalServiceCategory.businessAndAssociation => const [
      'Création d’entreprise',
      'Création d’association',
      'Statuts et gouvernance',
      'Immatriculation et formalités',
    ],
    ProfessionalServiceCategory.companies => const [
      'SARL',
      'SA',
      'SAS',
      'Succursale ou bureau de représentation',
    ],
    ProfessionalServiceCategory.cooperatives => const [
      'Coopérative simplifiée',
      'Coopérative avec conseil d’administration',
      'Statuts coopératifs',
      'Formalités d’agrément',
    ],
    ProfessionalServiceCategory.deepConsultation => const [
      'Analyse approfondie d’un dossier',
      'Second avis',
      'Stratégie juridique',
      'Consultation urgente',
    ],
  };
}
