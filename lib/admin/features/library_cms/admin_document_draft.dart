/// Où en est un brouillon dans le circuit de relecture (voir
/// migration_012_legal_document_review.sql).
enum DocumentDraftStatus {
  draft,
  inReview,
  changesRequested,
  published,
  archived;

  static DocumentDraftStatus fromWireName(String? value) {
    switch (value) {
      case 'in_review':
        return DocumentDraftStatus.inReview;
      case 'changes_requested':
        return DocumentDraftStatus.changesRequested;
      case 'published':
        return DocumentDraftStatus.published;
      case 'archived':
        return DocumentDraftStatus.archived;
      case 'draft':
      default:
        return DocumentDraftStatus.draft;
    }
  }
}

extension DocumentDraftStatusLabel on DocumentDraftStatus {
  String get label {
    switch (this) {
      case DocumentDraftStatus.draft:
        return 'Brouillon';
      case DocumentDraftStatus.inReview:
        return 'En relecture';
      case DocumentDraftStatus.changesRequested:
        return 'Corrections demandées';
      case DocumentDraftStatus.published:
        return 'Publié';
      case DocumentDraftStatus.archived:
        return 'Archivé';
    }
  }
}

/// Une ligne de `legal_document_drafts`, avec les e-mails résolus (voir
/// `jurisia_admin_list_document_drafts`). Le contenu du texte lui-même
/// (titre, articles…) reste dans [payload] — même forme JSON que
/// `tools/legal_import` (`ImportedDocument.toJson()`), volontairement pas
/// reportée en un modèle Dart typé côté console pour ne pas dupliquer ce
/// schéma à deux endroits tant que l'éditeur riche (phase 3 du cadrage)
/// n'existe pas.
class AdminDocumentDraft {
  const AdminDocumentDraft({
    required this.id,
    required this.documentId,
    required this.status,
    required this.payload,
    required this.createdByEmail,
    required this.submittedAt,
    required this.reviewedByEmail,
    required this.reviewedAt,
    required this.reviewReason,
    required this.updatedAt,
  });

  factory AdminDocumentDraft.fromRow(Map<String, dynamic> row) {
    return AdminDocumentDraft(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      status: DocumentDraftStatus.fromWireName(row['status'] as String?),
      payload: (row['payload'] as Map).cast<String, dynamic>(),
      createdByEmail: row['created_by_email'] as String?,
      submittedAt: DateTime.tryParse(row['submitted_at'] as String? ?? ''),
      reviewedByEmail: row['reviewed_by_email'] as String?,
      reviewedAt: DateTime.tryParse(row['reviewed_at'] as String? ?? ''),
      reviewReason: row['review_reason'] as String?,
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String documentId;
  final DocumentDraftStatus status;
  final Map<String, dynamic> payload;
  final String? createdByEmail;
  final DateTime? submittedAt;
  final String? reviewedByEmail;
  final DateTime? reviewedAt;
  final String? reviewReason;
  final DateTime updatedAt;

  String get title => (payload['title'] as String?) ?? documentId;
  String get type => (payload['type'] as String?) ?? '—';
  String get domain => (payload['domain'] as String?) ?? '—';
  String get reference => (payload['reference'] as String?) ?? '';
  String get summary => (payload['summary'] as String?) ?? '';
  int get articleCount => (payload['articles'] as List?)?.length ?? 0;

  bool get canEdit =>
      status == DocumentDraftStatus.draft || status == DocumentDraftStatus.changesRequested;
}
