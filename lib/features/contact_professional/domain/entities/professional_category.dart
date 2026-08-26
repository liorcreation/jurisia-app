/// Type de professionnel du droit que l'utilisateur souhaite contacter.
enum ProfessionalCategory {
  notaire,
  avocat,
  juriste,
  huissier,
  greffier,
  juge;

  static ProfessionalCategory fromName(String name) {
    return ProfessionalCategory.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ProfessionalCategory.juriste,
    );
  }
}

extension ProfessionalCategoryDetails on ProfessionalCategory {
  String get label {
    switch (this) {
      case ProfessionalCategory.notaire:
        return 'Notaire';
      case ProfessionalCategory.avocat:
        return 'Avocat';
      case ProfessionalCategory.juriste:
        return 'Juriste';
      case ProfessionalCategory.huissier:
        return 'Huissier';
      case ProfessionalCategory.greffier:
        return 'Greffier';
      case ProfessionalCategory.juge:
        return 'Juge';
    }
  }

  String get description {
    switch (this) {
      case ProfessionalCategory.notaire:
        return 'Actes authentiques, successions, immobilier, statuts de société.';
      case ProfessionalCategory.avocat:
        return 'Défense, représentation en justice, conseil et stratégie juridique.';
      case ProfessionalCategory.juriste:
        return "Conseil juridique d'entreprise, rédaction d'actes, veille réglementaire.";
      case ProfessionalCategory.huissier:
        return "Signification d'actes, constats, recouvrement, exécution des décisions.";
      case ProfessionalCategory.greffier:
        return 'Formalités judiciaires, dépôt et suivi administratif de dossiers.';
      case ProfessionalCategory.juge:
        return 'Orientation générale : juridiction compétente et étapes de la procédure.';
    }
  }

  /// Certaines catégories appellent une mise en garde avant l'envoi : un
  /// juge, à la différence des autres professions listées ici, ne peut pas
  /// être contacté à titre personnel au sujet d'une affaire (indépendance de
  /// la justice, risque de communication ex parte). `null` si aucune mise en
  /// garde n'est nécessaire pour cette catégorie.
  String? get formNotice {
    if (this != ProfessionalCategory.juge) return null;
    return "Un juge ne peut pas être contacté à titre personnel au sujet d'une affaire en cours. "
        'Cette demande sert uniquement à obtenir une orientation générale (juridiction compétente, '
        'étapes de la procédure), transmise par un partenaire juriste.';
  }
}
