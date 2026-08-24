import '../../../../models/legal_document/legal_document_model.dart';
import '../repositories/library_repository.dart';

/// Ajoute ou retire un document des favoris de l'utilisateur.
class ToggleBookmarkUseCase {
  ToggleBookmarkUseCase({required this.repository});

  final LibraryRepository repository;

  LegalDocument call(String documentId) => repository.toggleBookmark(documentId);
}
