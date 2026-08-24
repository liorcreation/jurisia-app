import 'package:flutter/foundation.dart';

import '../../domain/entities/drafting_chunk.dart';
import '../../domain/entities/drafting_request.dart';
import '../../domain/entities/legal_drafting_result.dart';
import '../../domain/entities/quick_adjustment.dart';
import '../../domain/repositories/professional_repository.dart';
import '../../domain/usecases/analyze_contract_usecase.dart';
import '../../domain/usecases/draft_legal_document_usecase.dart';

enum DraftingStatus { generating, ready, error }

/// Contrôleur d'état de l'espace de rédaction interactif : pilote la
/// génération (rédaction, consultation ou audit) au fil de l'eau, puis les
/// ajustements rapides appliqués au document obtenu.
class DraftingWorkspaceController extends ChangeNotifier {
  DraftingWorkspaceController({
    required this.request,
    required this.draftUseCase,
    required this.analyzeUseCase,
    required this.repository,
  }) {
    _generate();
  }

  final DraftingRequest request;
  final DraftLegalDocumentUseCase draftUseCase;
  final AnalyzeContractUseCase analyzeUseCase;
  final ProfessionalRepository repository;

  DraftingStatus _status = DraftingStatus.generating;
  DraftingStatus get status => _status;
  bool get isGenerating => _status == DraftingStatus.generating;

  String _streamingText = '';
  String get streamingText => _streamingText;

  LegalDraftingResult? _result;
  LegalDraftingResult? get result => _result;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> _generate() async {
    _status = DraftingStatus.generating;
    _streamingText = '';
    _errorMessage = null;
    notifyListeners();

    final stream = request.mode == DraftingMode.audit ? analyzeUseCase(request) : draftUseCase(request);
    await _consume(stream);
  }

  Future<void> regenerate() => _generate();

  Future<void> applyAdjustment(QuickAdjustment adjustment) async {
    final current = _result;
    if (current == null || isGenerating) return;

    _status = DraftingStatus.generating;
    _streamingText = '';
    _errorMessage = null;
    notifyListeners();

    await _consume(repository.applyQuickAdjustment(resultId: current.id, adjustment: adjustment));
  }

  Future<void> _consume(Stream<DraftingChunk> stream) async {
    try {
      await for (final chunk in stream) {
        switch (chunk) {
          case DraftingTextDeltaChunk(:final delta):
            _streamingText += delta;
            notifyListeners();
          case DraftingDoneChunk(:final result):
            _result = result;
            _streamingText = '';
            _status = DraftingStatus.ready;
            notifyListeners();
        }
      }
    } catch (error) {
      _status = DraftingStatus.error;
      _streamingText = '';
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  void toggleFavorite() {
    final current = _result;
    if (current == null) return;
    _result = repository.toggleFavorite(current.id);
    notifyListeners();
  }
}
