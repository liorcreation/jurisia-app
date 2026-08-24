import '../../../library/domain/entities/library_search_query.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';

/// Recherche croisée dans la bibliothèque juridique pour un usage
/// professionnel : retrouver les textes fondamentaux, jurisprudences ou
/// modèles d'actes pertinents pour un dossier en cours, en s'appuyant
/// directement sur le [LibraryRepository] de la Section 2.
class SearchProfessionalPrecedentsUseCase {
  SearchProfessionalPrecedentsUseCase({required this.libraryRepository});

  final LibraryRepository libraryRepository;

  List<LegalDocument> call({String keyword = '', LegalDomain? domain}) {
    return libraryRepository.search(LibrarySearchQuery(keyword: keyword, domain: domain));
  }
}
