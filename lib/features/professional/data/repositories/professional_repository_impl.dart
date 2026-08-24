import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/ai/claude_api_datasource.dart';
import '../../../../core/ai/hidden_block_stream_splitter.dart';
import '../../../../models/legal_document/legal_document_model.dart';
import '../../../../models/legal_document/legal_domain.dart';
import '../../../library/domain/entities/library_search_query.dart';
import '../../../library/domain/repositories/library_repository.dart';
import '../../domain/entities/drafting_chunk.dart';
import '../../domain/entities/drafting_request.dart';
import '../../domain/entities/legal_drafting_result.dart';
import '../../domain/entities/professional_template.dart';
import '../../domain/entities/quick_adjustment.dart';
import '../../domain/repositories/professional_repository.dart';
import '../datasources/professional_system_prompt.dart';
import '../datasources/professional_template_local_datasource.dart';

/// Implémentation du [ProfessionalRepository] : enrichit chaque requête du
/// contexte de la bibliothèque juridique avant de l'adresser au client
/// Claude partagé, et conserve les résultats générés en mémoire pour la
/// durée de la session (favoris, ajustements rapides).
class ProfessionalRepositoryImpl implements ProfessionalRepository {
  ProfessionalRepositoryImpl({
    required this.dataSource,
    required this.libraryRepository,
    required this.templateDataSource,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final ClaudeApiDataSource dataSource;
  final LibraryRepository libraryRepository;
  final ProfessionalTemplateDataSource templateDataSource;
  final Uuid _uuid;

  final Map<String, LegalDraftingResult> _resultsById = {};

  static const int _contextSize = 3;

  @override
  List<ProfessionalTemplate> get templates => templateDataSource.getAll();

  @override
  Stream<DraftingChunk> draftDocument(DraftingRequest request) async* {
    if (request.mode == DraftingMode.redaction) {
      final template = request.template;
      if (template == null) {
        throw ArgumentError('Un modèle est requis pour rédiger un acte.');
      }

      final context = _libraryContext(domain: template.domain);
      final system = ProfessionalSystemPrompt.drafting(
        actTitle: template.title,
        actDescription: template.description,
        fieldValues: request.fieldValues,
        instructions: request.instructions,
        libraryContext: context,
      );

      yield* _generate(
        mode: DraftingMode.redaction,
        title: template.title,
        system: system,
        userMessage: 'Rédige le document demandé.',
        citedSources: context,
      );
      return;
    }

    // Consultation approfondie et note de synthèse.
    final question = request.instructions.trim();
    if (question.isEmpty) {
      throw ArgumentError('La question de consultation ne peut pas être vide.');
    }

    final context = _libraryContext(domain: request.domainHint);
    final system = ProfessionalSystemPrompt.consultation(question: question, libraryContext: context);

    yield* _generate(
      mode: DraftingMode.consultation,
      title: 'Note de synthèse',
      system: system,
      userMessage: 'Rédige la note de synthèse demandée.',
      citedSources: context,
    );
  }

  @override
  Stream<DraftingChunk> analyzeContract(DraftingRequest request) async* {
    final contractText = request.contractText?.trim() ?? '';
    if (contractText.isEmpty) {
      throw ArgumentError('Le texte du contrat à auditer ne peut pas être vide.');
    }

    final context = _libraryContext(domain: request.domainHint);
    final system = ProfessionalSystemPrompt.audit(
      contractText: contractText,
      instructions: request.instructions,
      libraryContext: context,
    );

    final splitter = HiddenBlockStreamSplitter(markerStart: ProfessionalSystemPrompt.risksMarkerStart);

    await for (final delta in dataSource.streamCompletion(
      system: system,
      messages: const [
        {'role': 'user', 'content': 'Audite le contrat fourni.'},
      ],
      maxTokens: 3072,
    )) {
      final visiblePart = splitter.feed(delta);
      if (visiblePart.isNotEmpty) yield DraftingTextDeltaChunk(visiblePart);
    }
    final tail = splitter.flush();
    if (tail.isNotEmpty) yield DraftingTextDeltaChunk(tail);

    final risks = _parseRisks(splitter.hidden.toString());

    final result = LegalDraftingResult(
      id: _uuid.v4(),
      mode: DraftingMode.audit,
      title: 'Audit de contrat',
      content: splitter.visibleAccumulated.toString().trim(),
      generatedAt: DateTime.now(),
      risks: risks,
      citedSources: _toCitedSources(context),
    );

    _resultsById[result.id] = result;
    yield DraftingDoneChunk(result);
  }

  @override
  Stream<DraftingChunk> applyQuickAdjustment({
    required String resultId,
    required QuickAdjustment adjustment,
  }) async* {
    final current = _resultsById[resultId];
    if (current == null) {
      throw ArgumentError('Résultat introuvable : $resultId');
    }

    final system = ProfessionalSystemPrompt.quickAdjustment(
      currentDocument: current.content,
      instruction: adjustment.instruction,
    );

    final buffer = StringBuffer();
    await for (final delta in dataSource.streamCompletion(
      system: system,
      messages: const [
        {'role': 'user', 'content': 'Applique la modification demandée.'},
      ],
    )) {
      buffer.write(delta);
      yield DraftingTextDeltaChunk(delta);
    }

    final updated = current.copyWith(content: buffer.toString().trim(), generatedAt: DateTime.now());
    _resultsById[resultId] = updated;
    yield DraftingDoneChunk(updated);
  }

  Stream<DraftingChunk> _generate({
    required DraftingMode mode,
    required String title,
    required String system,
    required String userMessage,
    required List<LegalDocument> citedSources,
  }) async* {
    final buffer = StringBuffer();
    await for (final delta in dataSource.streamCompletion(
      system: system,
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
      maxTokens: 3072,
    )) {
      buffer.write(delta);
      yield DraftingTextDeltaChunk(delta);
    }

    final result = LegalDraftingResult(
      id: _uuid.v4(),
      mode: mode,
      title: title,
      content: buffer.toString().trim(),
      generatedAt: DateTime.now(),
      citedSources: _toCitedSources(citedSources),
    );

    _resultsById[result.id] = result;
    yield DraftingDoneChunk(result);
  }

  List<LegalDocument> _libraryContext({required LegalDomain? domain}) {
    final results = libraryRepository.search(LibrarySearchQuery(domain: domain));
    return results.take(_contextSize).toList();
  }

  List<CitedLegalSource> _toCitedSources(List<LegalDocument> documents) {
    return documents.map((doc) => CitedLegalSource(title: doc.title, reference: doc.reference)).toList();
  }

  List<ClauseRisk> _parseRisks(String raw) {
    if (raw.isEmpty) return const [];

    var content = raw.trim();
    if (content.startsWith(ProfessionalSystemPrompt.risksMarkerStart)) {
      content = content.substring(ProfessionalSystemPrompt.risksMarkerStart.length);
    }
    final endIndex = content.indexOf(ProfessionalSystemPrompt.risksMarkerEnd);
    if (endIndex != -1) {
      content = content.substring(0, endIndex);
    }
    content = content.trim();
    if (content.isEmpty) return const [];

    try {
      final decoded = jsonDecode(content);
      if (decoded is! List) return const [];

      return decoded.map((item) {
        final map = item as Map<String, dynamic>;
        return ClauseRisk(
          clauseExcerpt: map['clauseExcerpt'] as String? ?? '',
          riskLevel: RiskLevel.fromName(map['riskLevel'] as String? ?? 'moyen'),
          explanation: map['explanation'] as String? ?? '',
          suggestedRewrite: map['suggestedRewrite'] as String? ?? '',
        );
      }).toList();
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  LegalDraftingResult? findResult(String resultId) => _resultsById[resultId];

  @override
  LegalDraftingResult toggleFavorite(String resultId) {
    final current = _resultsById[resultId];
    if (current == null) {
      throw ArgumentError('Résultat introuvable : $resultId');
    }
    final updated = current.copyWith(isFavorite: !current.isFavorite);
    _resultsById[resultId] = updated;
    return updated;
  }

  @override
  void dispose() => dataSource.dispose();
}
