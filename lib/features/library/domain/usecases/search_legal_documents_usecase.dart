import '../../../../models/legal_document/legal_document_model.dart';
import '../entities/library_search_query.dart';
import '../repositories/library_repository.dart';

/// Exécute une recherche multi-critères dans la bibliothèque juridique.
class SearchLegalDocumentsUseCase {
  SearchLegalDocumentsUseCase({required this.repository});

  final LibraryRepository repository;

  List<LegalDocument> call(LibrarySearchQuery query) => repository.search(query);
}
