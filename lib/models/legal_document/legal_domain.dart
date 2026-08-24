/// Branches du droit utilisées pour qualifier une consultation, un document
/// de la bibliothèque juridique ou un module de cours.
enum LegalDomain {
  civil,
  penal,
  commercial,
  travail,
  famille,
  administratif,
  fiscal,
  constitutionnel,
  foncier,
  ohada,
  procedureCivile,
  procedurePenale,
  autre;

  String get label {
    switch (this) {
      case LegalDomain.civil:
        return 'Droit civil';
      case LegalDomain.penal:
        return 'Droit pénal';
      case LegalDomain.commercial:
        return 'Droit commercial';
      case LegalDomain.travail:
        return 'Droit du travail';
      case LegalDomain.famille:
        return 'Droit de la famille';
      case LegalDomain.administratif:
        return 'Droit administratif';
      case LegalDomain.fiscal:
        return 'Droit fiscal';
      case LegalDomain.constitutionnel:
        return 'Droit constitutionnel';
      case LegalDomain.foncier:
        return 'Droit foncier';
      case LegalDomain.ohada:
        return 'Droit OHADA';
      case LegalDomain.procedureCivile:
        return 'Procédure civile';
      case LegalDomain.procedurePenale:
        return 'Procédure pénale';
      case LegalDomain.autre:
        return 'Autre matière';
    }
  }

  static LegalDomain fromName(String name) {
    return LegalDomain.values.firstWhere(
      (domain) => domain.name == name,
      orElse: () => LegalDomain.autre,
    );
  }
}
