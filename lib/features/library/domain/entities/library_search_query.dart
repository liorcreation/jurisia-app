import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Requête multi-critères adressée au moteur de recherche de la
/// bibliothèque juridique.
class LibrarySearchQuery {
  const LibrarySearchQuery({
    this.keyword = '',
    this.type,
    this.domain,
    this.dateFrom,
    this.dateTo,
    this.favoritesOnly = false,
  });

  /// Recherche libre : titre, référence (numéro d'article/de texte), résumé,
  /// contenu intégral et mots-clés.
  final String keyword;

  /// Catégorie de document (Constitution, Code, Loi, Décret, Arrêté,
  /// Jurisprudence, Traité, Modèle d'acte).
  final LegalDocumentType? type;

  /// Branche du droit.
  final LegalDomain? domain;

  /// Borne inférieure (incluse) de la date de publication.
  final DateTime? dateFrom;

  /// Borne supérieure (incluse) de la date de publication.
  final DateTime? dateTo;

  /// Ne renvoie que les documents marqués comme favoris.
  final bool favoritesOnly;
}
