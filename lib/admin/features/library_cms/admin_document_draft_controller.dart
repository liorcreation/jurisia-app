import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_document_draft.dart';
import 'admin_document_draft_repository.dart';

/// État de l'écran « CMS Bibliothèque » : la file des brouillons, filtrable
/// par statut, et les actions du circuit de relecture. Les messages
/// d'erreur du serveur (motif manquant, brouillon plus modifiable…) sont
/// déjà en français et actionnables — affichés tels quels.
class AdminDocumentDraftController extends ChangeNotifier {
  AdminDocumentDraftController({required this.repository}) {
    // ignore: unawaited_futures
    load();
  }

  final AdminDocumentDraftRepository repository;

  List<AdminDocumentDraft> _drafts = const [];
  bool _loading = false;
  bool _mutating = false;
  String? _error;
  DocumentDraftStatus? _filter;

  bool get isLoading => _loading;
  bool get isMutating => _mutating;
  String? get error => _error;
  DocumentDraftStatus? get filter => _filter;

  List<AdminDocumentDraft> get drafts {
    if (_filter == null) return _drafts;
    return _drafts.where((d) => d.status == _filter).toList();
  }

  int get totalCount => _drafts.length;

  int countFor(DocumentDraftStatus status) => _drafts.where((d) => d.status == status).length;

  void setFilter(DocumentDraftStatus? status) {
    _filter = status;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _drafts = await repository.list();
    } catch (error) {
      _error = 'Chargement des brouillons impossible. Vérifiez vos droits.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Retourne `true` en cas de succès.
  Future<bool> createDraft({
    required String documentId,
    required Map<String, dynamic> payload,
  }) => _mutate(() => repository.saveDraft(draftId: null, documentId: documentId, payload: payload));

  Future<bool> updateDraft(AdminDocumentDraft draft, Map<String, dynamic> payload) => _mutate(
        () => repository.saveDraft(draftId: draft.id, documentId: draft.documentId, payload: payload),
      );

  Future<bool> submit(String draftId) => _mutate(() => repository.submit(draftId));

  Future<bool> approve(String draftId) =>
      _mutate(() => repository.review(draftId: draftId, approve: true));

  Future<bool> requestChanges(String draftId, String reason) =>
      _mutate(() => repository.review(draftId: draftId, approve: false, reason: reason));

  Future<bool> archiveDocument(String documentId, String? reason) =>
      _mutate(() => repository.archiveDocument(documentId: documentId, reason: reason));

  Future<bool> _mutate(Future<void> Function() action) async {
    _mutating = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      await load();
      return true;
    } on PostgrestException catch (error) {
      _error = error.message;
      return false;
    } catch (error) {
      _error = 'L\'action n\'a pas pu être enregistrée.';
      return false;
    } finally {
      _mutating = false;
      notifyListeners();
    }
  }

  void dismissError() {
    _error = null;
    notifyListeners();
  }
}
