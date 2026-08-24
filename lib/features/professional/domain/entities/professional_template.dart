import '../../../../models/legal_document/legal_domain.dart';

/// Type d'acte proposé en rédaction rapide dans l'Espace professionnel.
enum DraftingActType {
  bailCommercial,
  contratPrestation,
  statutsSociete,
  contratTravail,
}

extension DraftingActTypeLabel on DraftingActType {
  String get label {
    switch (this) {
      case DraftingActType.bailCommercial:
        return 'Bail commercial';
      case DraftingActType.contratPrestation:
        return 'Contrat de prestation';
      case DraftingActType.statutsSociete:
        return 'Statuts SARL/SAS';
      case DraftingActType.contratTravail:
        return 'Contrat de travail';
    }
  }
}

/// Modèle d'acte proposé dans le tableau de bord professionnel : décrit le
/// type de document, les informations à renseigner pour le générer, et la
/// branche du droit à privilégier pour enrichir le contexte de l'IA depuis
/// la bibliothèque juridique.
class ProfessionalTemplate {
  const ProfessionalTemplate({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.domain,
    required this.requiredFields,
  });

  final String id;
  final DraftingActType type;
  final String title;
  final String description;
  final LegalDomain domain;

  /// Libellés des informations à renseigner par l'utilisateur pour générer
  /// l'acte (ex. « Nom du bailleur », « Durée du bail »...).
  final List<String> requiredFields;
}
