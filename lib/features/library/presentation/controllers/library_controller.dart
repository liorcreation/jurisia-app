import 'package:flutter/foundation.dart';

import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../domain/entities/library_search_query.dart';
import '../../domain/repositories/library_repository.dart';
import '../../domain/usecases/search_legal_documents_usecase.dart';
import '../../domain/usecases/toggle_bookmark_usecase.dart';

/// Contrôleur d'état de l'écran Bibliothèque juridique : conserve les
/// critères de recherche courants et les résultats, et relaie les
/// mutations (favoris, téléchargements) au repository.
class LibraryController extends ChangeNotifier {
  LibraryController({
    required this.searchUseCase,
    required this.toggleBookmarkUseCase,
    required this.repository,
  }) {
    _runSearch();
  }

  final SearchLegalDocumentsUseCase searchUseCase;
  final ToggleBookmarkUseCase toggleBookmarkUseCase;
  final LibraryRepository repository;

  String _keyword = '';
  LegalDocumentType? _selectedType;
  LegalDomain? _selectedDomain;
  bool _favoritesOnly = false;
  List<LegalDocument> _results = const [];

  String get keyword => _keyword;
  LegalDocumentType? get selectedType => _selectedType;
  LegalDomain? get selectedDomain => _selectedDomain;
  bool get favoritesOnly => _favoritesOnly;
  List<LegalDocument> get results => _results;

  /// Consultation directe par identifiant, utilisée par la visionneuse de
  /// document pour rester à jour même si le document a quitté la liste de
  /// résultats filtrée courante.
  LegalDocument? documentById(String id) => repository.findById(id);

  void updateKeyword(String value) {
    _keyword = value;
    _runSearch();
  }

  void selectType(LegalDocumentType? type) {
    _selectedType = _selectedType == type ? null : type;
    _runSearch();
  }

  void selectDomain(LegalDomain? domain) {
    _selectedDomain = _selectedDomain == domain ? null : domain;
    _runSearch();
  }

  void toggleFavoritesOnly() {
    _favoritesOnly = !_favoritesOnly;
    _runSearch();
  }

  void toggleBookmark(String documentId) {
    toggleBookmarkUseCase(documentId);
    _runSearch();
  }

  void recordDownload(String documentId) {
    repository.recordDownload(documentId);
    _runSearch();
  }

  void _runSearch() {
    _results = searchUseCase(
      LibrarySearchQuery(
        keyword: _keyword,
        type: _selectedType,
        domain: _selectedDomain,
        favoritesOnly: _favoritesOnly,
      ),
    );
    notifyListeners();
  }
}
