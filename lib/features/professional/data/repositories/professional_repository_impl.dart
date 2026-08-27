import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/ai/groq_api_datasource.dart';
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
/// Groq partagé, et conserve les résultats générés en mémoire pour une
/// réactivité immédiate (favoris, ajustements rapides), synchronisés en
/// arrière-plan avec Supabase quand [supabaseClient] et [userId] sont
/// fournis.
class ProfessionalRepositoryImpl implements ProfessionalRepository {
  ProfessionalRepositoryImpl({
    required this.dataSource,
    required this.libraryRepository,
    required this.templateDataSource,
    this.supabaseClient,
    this.userId,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  final LlmDataSource dataSource;
  final LibraryRepository libraryRepository;
  final ProfessionalTemplateDataSource templateDataSource;
  final SupabaseClient? supabaseClient;
  final String? userId;
  final Uuid _uuid;

  final Map<String, LegalDraftingResult> _resultsById = {};

  static const int _contextSize = 3;

  bool get _persistenceEnabled => supabaseClient != null && userId != null;

  @override
  List<ProfessionalTemplate> get templates => templateDataSource.getAll();

  @override
  List<LegalDraftingResult> get recentResults {
    final all = _resultsById.values.toList()
      ..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
    return all;
  }

  @override
  Future<void> hydrate() async {
    if (!_persistenceEnabled) return;

    try {
      final rows = await supabaseClient!
          .from('professional_drafting_results')
          .select()
          .eq('user_id', userId!)
          .order('created_at', ascending: false)
          .limit(50);

      for (final row in rows as List) {
        final result = _resultFromRow(row as Map<String, dynamic>);
        _resultsById[result.id] = result;
      }
    } catch (error) {
      // ignore: avoid_print
      print('Échec du chargement des documents professionnels Supabase : $error');
    }
  }

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
        libraryContext: context,
      );
      final userMessage = ProfessionalSystemPrompt.draftingUserMessage(
        fieldValues: request.fieldValues,
        instructions: request.instructions,
      );

      yield* _generate(
        mode: DraftingMode.redaction,
        title: template.title,
        system: system,
        userMessage: userMessage,
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
    final system = ProfessionalSystemPrompt.consultation(libraryContext: context);

    yield* _generate(
      mode: DraftingMode.consultation,
      title: 'Note de synthèse',
      system: system,
      userMessage: ProfessionalSystemPrompt.consultationUserMessage(question),
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
    final system = ProfessionalSystemPrompt.audit(libraryContext: context);
    final userMessage = ProfessionalSystemPrompt.auditUserMessage(
      contractText: contractText,
      instructions: request.instructions,
    );

    final splitter = HiddenBlockStreamSplitter(markerStart: ProfessionalSystemPrompt.risksMarkerStart);

    await for (final delta in dataSource.streamCompletion(
      system: system,
      messages: [
        {'role': 'user', 'content': userMessage},
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
    _persistNewResult(result);
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

    final system = ProfessionalSystemPrompt.quickAdjustment();
    final userMessage = ProfessionalSystemPrompt.quickAdjustmentUserMessage(
      currentDocument: current.content,
      instruction: adjustment.instruction,
    );

    final buffer = StringBuffer();
    await for (final delta in dataSource.streamCompletion(
      system: system,
      messages: [
        {'role': 'user', 'content': userMessage},
      ],
    )) {
      buffer.write(delta);
      yield DraftingTextDeltaChunk(delta);
    }

    final updated = current.copyWith(content: buffer.toString().trim(), generatedAt: DateTime.now());
    _resultsById[resultId] = updated;
    _persistContentUpdate(updated);
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
    _persistNewResult(result);
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
    _persistFavorite(updated);
    return updated;
  }

  // -- Persistance Supabase (meilleur effort, en arrière-plan) -------------

  void _persistNewResult(LegalDraftingResult result) {
    if (!_persistenceEnabled) return;

    supabaseClient!.from('professional_drafting_results').insert({
      'id': result.id,
      'user_id': userId,
      'mode': result.mode.name,
      'title': result.title,
      'content': result.content,
      'risks': result.risks.map(_riskToJson).toList(),
      'cited_sources': result.citedSources.map(_sourceToJson).toList(),
      'is_favorite': result.isFavorite,
    }).catchError((Object error) {
      // ignore: avoid_print
      print("Échec de l'enregistrement du document ${result.id} : $error");
    });
  }

  void _persistContentUpdate(LegalDraftingResult result) {
    if (!_persistenceEnabled) return;

    supabaseClient!
        .from('professional_drafting_results')
        .update({
          'content': result.content,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', result.id)
        .catchError((Object error) {
          // ignore: avoid_print
          print('Échec de synchronisation du document ${result.id} : $error');
        });
  }

  void _persistFavorite(LegalDraftingResult result) {
    if (!_persistenceEnabled) return;

    supabaseClient!
        .from('professional_drafting_results')
        .update({'is_favorite': result.isFavorite})
        .eq('id', result.id)
        .catchError((Object error) {
          // ignore: avoid_print
          print('Échec de synchronisation du favori ${result.id} : $error');
        });
  }

  Map<String, dynamic> _riskToJson(ClauseRisk risk) => {
        'clauseExcerpt': risk.clauseExcerpt,
        'riskLevel': risk.riskLevel.name,
        'explanation': risk.explanation,
        'suggestedRewrite': risk.suggestedRewrite,
      };

  Map<String, dynamic> _sourceToJson(CitedLegalSource source) => {
        'title': source.title,
        'reference': source.reference,
      };

  LegalDraftingResult _resultFromRow(Map<String, dynamic> row) {
    final risksJson = row['risks'] as List<dynamic>? ?? const [];
    final sourcesJson = row['cited_sources'] as List<dynamic>? ?? const [];

    return LegalDraftingResult(
      id: row['id'] as String,
      mode: DraftingMode.values.firstWhere(
        (value) => value.name == row['mode'],
        orElse: () => DraftingMode.consultation,
      ),
      title: row['title'] as String,
      content: row['content'] as String,
      generatedAt: DateTime.parse((row['updated_at'] ?? row['created_at']) as String),
      risks: risksJson
          .map(
            (json) => ClauseRisk(
              clauseExcerpt: (json as Map<String, dynamic>)['clauseExcerpt'] as String? ?? '',
              riskLevel: RiskLevel.fromName(json['riskLevel'] as String? ?? 'moyen'),
              explanation: json['explanation'] as String? ?? '',
              suggestedRewrite: json['suggestedRewrite'] as String? ?? '',
            ),
          )
          .toList(),
      citedSources: sourcesJson
          .map(
            (json) => CitedLegalSource(
              title: (json as Map<String, dynamic>)['title'] as String? ?? '',
              reference: json['reference'] as String? ?? '',
            ),
          )
          .toList(),
      isFavorite: row['is_favorite'] as bool? ?? false,
    );
  }

  @override
  void dispose() => dataSource.dispose();
}
