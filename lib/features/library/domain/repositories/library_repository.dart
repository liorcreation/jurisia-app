import '../../../../models/legal_document/legal_document_model.dart';
import '../entities/library_search_query.dart';

/// Frontière du domaine vers la source des documents juridiques (locale
/// aujourd'hui, potentiellement distante demain sans impact sur le domaine
/// ou la présentation).
abstract class LibraryRepository {
  /// Filtrage synchrone multi-critères (mot-clé, référence, type, domaine,
  /// dates, favoris).
  List<LegalDocument> search(LibrarySearchQuery query);

  /// Retrouve un document par identifiant, ou `null` s'il n'existe pas.
  LegalDocument? findById(String id);

  /// Bascule l'état favori d'un document et retourne sa version mise à jour.
  LegalDocument toggleBookmark(String documentId);

  /// Incrémente le compteur de téléchargement d'un document et retourne sa
  /// version mise à jour.
  LegalDocument recordDownload(String documentId);
}
