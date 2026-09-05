import '../../../core/ai/prompt_keys.dart' as core;

/// Clés de prompt reconnues — voir `PromptKeys` (core/ai/prompt_keys.dart),
/// la même liste que celle branchée sur les prompts système réels
/// (litige, tuteur de module, atelier professionnel). Réexposées ici sous
/// un nom historique de cet écran ; la source de vérité reste `PromptKeys`.
class PromptKey {
  const PromptKey._();
  static const litige = core.PromptKeys.litige;
  static const tuteur = core.PromptKeys.tuteur;
  static const redaction = core.PromptKeys.redaction;
  static const audit = core.PromptKeys.audit;
  static const consultation = core.PromptKeys.consultation;

  static const all = [litige, tuteur, redaction, audit, consultation];

  static String label(String key) {
    switch (key) {
      case litige:
        return 'Litiges et consultations';
      case tuteur:
        return 'Tuteur de module (étudiant)';
      case redaction:
        return 'Rédaction d\'acte';
      case audit:
        return 'Audit de contrat';
      case consultation:
        return 'Consultation professionnelle approfondie';
      default:
        return key;
    }
  }
}

enum AiPromptStatus {
  draft,
  tested,
  published,
  archived;

  static AiPromptStatus fromWireName(String? value) {
    switch (value) {
      case 'tested':
        return AiPromptStatus.tested;
      case 'published':
        return AiPromptStatus.published;
      case 'archived':
        return AiPromptStatus.archived;
      case 'draft':
      default:
        return AiPromptStatus.draft;
    }
  }
}

extension AiPromptStatusLabel on AiPromptStatus {
  String get label {
    switch (this) {
      case AiPromptStatus.draft:
        return 'Brouillon';
      case AiPromptStatus.tested:
        return 'Testé';
      case AiPromptStatus.published:
        return 'Publié';
      case AiPromptStatus.archived:
        return 'Archivé';
    }
  }
}

/// Une ligne de `ai_prompts`, avec les e-mails résolus (voir
/// `jurisia_admin_list_prompts`).
class AdminAiPrompt {
  const AdminAiPrompt({
    required this.id,
    required this.key,
    required this.content,
    required this.status,
    required this.testMessage,
    required this.testResponse,
    required this.testedAt,
    required this.createdByEmail,
    required this.approvedByEmail,
    required this.approvedAt,
    required this.updatedAt,
  });

  factory AdminAiPrompt.fromRow(Map<String, dynamic> row) {
    return AdminAiPrompt(
      id: row['id'] as String,
      key: row['key'] as String,
      content: row['content'] as String,
      status: AiPromptStatus.fromWireName(row['status'] as String?),
      testMessage: row['test_message'] as String?,
      testResponse: row['test_response'] as String?,
      testedAt: DateTime.tryParse(row['tested_at'] as String? ?? ''),
      createdByEmail: row['created_by_email'] as String?,
      approvedByEmail: row['approved_by_email'] as String?,
      approvedAt: DateTime.tryParse(row['approved_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String key;
  final String content;
  final AiPromptStatus status;
  final String? testMessage;
  final String? testResponse;
  final DateTime? testedAt;
  final String? createdByEmail;
  final String? approvedByEmail;
  final DateTime? approvedAt;
  final DateTime updatedAt;

  bool get isEditable => status != AiPromptStatus.published;

  /// `true` si ce brouillon a été testé au moins une fois (condition
  /// nécessaire à la publication, y compris pour republier une version
  /// archivée sans repasser par un nouveau test).
  bool get canPublish => testedAt != null;
}
