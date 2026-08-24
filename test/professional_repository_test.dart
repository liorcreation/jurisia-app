import 'package:flutter_test/flutter_test.dart';
import 'package:jurisia_app/core/ai/claude_api_datasource.dart';
import 'package:jurisia_app/features/library/data/datasources/legal_document_local_datasource.dart';
import 'package:jurisia_app/features/library/data/repositories/library_repository_impl.dart';
import 'package:jurisia_app/features/professional/data/datasources/professional_template_local_datasource.dart';
import 'package:jurisia_app/features/professional/data/repositories/professional_repository_impl.dart';
import 'package:jurisia_app/features/professional/domain/entities/drafting_chunk.dart';
import 'package:jurisia_app/features/professional/domain/entities/drafting_request.dart';
import 'package:jurisia_app/features/professional/domain/entities/legal_drafting_result.dart';
import 'package:jurisia_app/features/professional/domain/entities/professional_template.dart';
import 'package:jurisia_app/features/professional/domain/entities/quick_adjustment.dart';
import 'package:jurisia_app/features/professional/domain/repositories/professional_repository.dart';
import 'package:jurisia_app/features/professional/domain/usecases/analyze_contract_usecase.dart';
import 'package:jurisia_app/features/professional/domain/usecases/draft_legal_document_usecase.dart';
import 'package:jurisia_app/features/professional/domain/usecases/search_professional_precedents_usecase.dart';
import 'package:jurisia_app/models/legal_document/legal_domain.dart';

class _FakeDataSource implements ClaudeApiDataSource {
  _FakeDataSource(this._responses);

  final List<List<String>> _responses;
  final List<String> systemPromptsSeen = [];
  var _callIndex = 0;
  var disposed = false;

  @override
  Stream<String> streamCompletion({
    required String system,
    required List<Map<String, String>> messages,
    int maxTokens = 1536,
  }) async* {
    systemPromptsSeen.add(system);
    final chunks = _responses[_callIndex];
    _callIndex++;
    for (final chunk in chunks) {
      yield chunk;
    }
  }

  @override
  void dispose() => disposed = true;
}

ProfessionalTemplate _templateByType(DraftingActType type) {
  const dataSource = LocalProfessionalTemplateDataSource();
  return dataSource.getAll().firstWhere((template) => template.type == type);
}

({ProfessionalRepository repository, _FakeDataSource fakeDataSource}) _buildRepository(
  List<List<String>> responses,
) {
  final fakeDataSource = _FakeDataSource(responses);
  final repository = ProfessionalRepositoryImpl(
    dataSource: fakeDataSource,
    libraryRepository: LibraryRepositoryImpl(dataSource: const LocalLegalDocumentDataSource()),
    templateDataSource: const LocalProfessionalTemplateDataSource(),
  );
  return (repository: repository, fakeDataSource: fakeDataSource);
}

void main() {
  group('DraftLegalDocumentUseCase — rédaction', () {
    test('rédige un acte à partir d\'un modèle et enrichit le contexte depuis la bibliothèque', () async {
      final built = _buildRepository([
        ['Article 1 — Objet du contrat. ', 'Article 2 — Durée et rémunération.'],
      ]);
      final useCase = DraftLegalDocumentUseCase(repository: built.repository);

      final template = _templateByType(DraftingActType.contratTravail);
      final request = DraftingRequest(
        mode: DraftingMode.redaction,
        template: template,
        fieldValues: const {
          "Nom de l'employeur": 'ACME SARL',
          'Nom du salarié': 'Jean Dupont',
          'Intitulé du poste': 'Juriste',
          'Type de contrat (CDI ou CDD)': 'CDI',
          'Durée du travail': '35h/semaine',
          'Rémunération mensuelle brute': '2500 €',
        },
      );

      final events = await useCase(request).toList();
      final deltas = events.whereType<DraftingTextDeltaChunk>().map((e) => e.delta).join();
      final done = events.whereType<DraftingDoneChunk>().single.result;

      expect(deltas, 'Article 1 — Objet du contrat. Article 2 — Durée et rémunération.');
      expect(done.mode, DraftingMode.redaction);
      expect(done.title, 'Contrat de travail');
      expect(done.content, deltas.trim());
      expect(done.citedSources, hasLength(3));
      expect(done.citedSources.map((s) => s.title), contains('Code du travail'));

      expect(built.fakeDataSource.systemPromptsSeen.single, contains('ACME SARL'));
      expect(built.fakeDataSource.systemPromptsSeen.single, contains('Code du travail'));
    });

    test('lève une erreur si aucun modèle n\'est fourni en mode rédaction', () async {
      final built = _buildRepository([]);
      final useCase = DraftLegalDocumentUseCase(repository: built.repository);

      await expectLater(
        useCase(const DraftingRequest(mode: DraftingMode.redaction)).toList(),
        throwsArgumentError,
      );
    });
  });

  group('DraftLegalDocumentUseCase — consultation', () {
    test('produit une note de synthèse et cite les textes du domaine indiqué', () async {
      final built = _buildRepository([
        ['Analyse de la question posée, avec conclusion opérationnelle.'],
      ]);
      final useCase = DraftLegalDocumentUseCase(repository: built.repository);

      final request = DraftingRequest(
        mode: DraftingMode.consultation,
        instructions: 'Un salarié peut-il être licencié sans préavis ?',
        domainHint: LegalDomain.travail,
      );

      final events = await useCase(request).toList();
      final done = events.whereType<DraftingDoneChunk>().single.result;

      expect(done.mode, DraftingMode.consultation);
      expect(done.title, 'Note de synthèse');
      expect(done.content, 'Analyse de la question posée, avec conclusion opérationnelle.');
      expect(done.citedSources, isNotEmpty);
    });

    test('lève une erreur si la question de consultation est vide', () async {
      final built = _buildRepository([]);
      final useCase = DraftLegalDocumentUseCase(repository: built.repository);

      await expectLater(
        useCase(const DraftingRequest(mode: DraftingMode.consultation)).toList(),
        throwsArgumentError,
      );
    });
  });

  group('AnalyzeContractUseCase', () {
    const riskJson = '[{"clauseExcerpt":"Le prestataire peut resilier a tout moment sans preavis.",'
        '"riskLevel":"eleve",'
        '"explanation":"Clause desequilibree au detriment du client.",'
        '"suggestedRewrite":"Chaque partie pourra resilier moyennant un preavis de 30 jours."}]';

    test('sépare la synthèse visible du bloc de risques, même fragmenté sur plusieurs paquets', () async {
      final built = _buildRepository([
        [
          'Le contrat présente un déséquilibre notable au détriment du client. ',
          '<<<JURISIA_RI', // marqueur volontairement coupé en deux fragments
          'SKS_JSON>>>\n$riskJson\n<<<END_JURISIA_RISKS_JSON>>>',
        ],
      ]);
      final useCase = AnalyzeContractUseCase(repository: built.repository);

      final request = DraftingRequest(
        mode: DraftingMode.audit,
        contractText: 'Article 4 : Le prestataire peut résilier à tout moment sans préavis.',
        domainHint: LegalDomain.commercial,
      );

      final events = await useCase(request).toList();
      final deltas = events.whereType<DraftingTextDeltaChunk>().map((e) => e.delta).join();
      final done = events.whereType<DraftingDoneChunk>().single.result;

      expect(deltas, 'Le contrat présente un déséquilibre notable au détriment du client. ');
      expect(deltas.contains('RISKS_JSON'), isFalse);

      expect(done.mode, DraftingMode.audit);
      expect(done.risks, hasLength(1));
      expect(done.risks.single.riskLevel, RiskLevel.eleve);
      expect(done.risks.single.suggestedRewrite, contains('preavis de 30 jours'));
      expect(done.citedSources.map((s) => s.title).toSet(), {
        'Code de commerce',
        'Loi relative au bail à usage professionnel',
      });
    });

    test('lève une erreur si le texte du contrat à auditer est vide', () async {
      final built = _buildRepository([]);
      final useCase = AnalyzeContractUseCase(repository: built.repository);

      await expectLater(
        useCase(const DraftingRequest(mode: DraftingMode.audit)).toList(),
        throwsArgumentError,
      );
    });

    test('retourne une liste de risques vide si le bloc caché est absent ou malformé', () async {
      final built = _buildRepository([
        ['Le contrat ne présente pas de clause manifestement abusive.'],
      ]);
      final useCase = AnalyzeContractUseCase(repository: built.repository);

      final request = DraftingRequest(mode: DraftingMode.audit, contractText: 'Contrat simple.');
      final events = await useCase(request).toList();
      final done = events.whereType<DraftingDoneChunk>().single.result;

      expect(done.risks, isEmpty);
    });
  });

  group('Favoris et ajustements rapides', () {
    test('toggleFavorite bascule l\'état favori du résultat', () async {
      final built = _buildRepository([
        ['Texte du document.'],
      ]);
      final useCase = DraftLegalDocumentUseCase(repository: built.repository);

      final template = _templateByType(DraftingActType.bailCommercial);
      final request = DraftingRequest(
        mode: DraftingMode.redaction,
        template: template,
        fieldValues: {for (final field in template.requiredFields) field: 'valeur'},
      );

      final events = await useCase(request).toList();
      final result = events.whereType<DraftingDoneChunk>().single.result;
      expect(result.isFavorite, isFalse);

      final toggledOn = built.repository.toggleFavorite(result.id);
      expect(toggledOn.isFavorite, isTrue);
      expect(built.repository.findResult(result.id)!.isFavorite, isTrue);

      final toggledOff = built.repository.toggleFavorite(result.id);
      expect(toggledOff.isFavorite, isFalse);
    });

    test('toggleFavorite lève une erreur pour un identifiant inconnu', () {
      final built = _buildRepository([]);
      expect(() => built.repository.toggleFavorite('inconnu'), throwsArgumentError);
    });

    test('applyQuickAdjustment régénère le contenu en conservant l\'identifiant du résultat', () async {
      final built = _buildRepository([
        ['Version initiale du contrat.'],
        ['Version renforcée et plus stricte du contrat.'],
      ]);
      final draftUseCase = DraftLegalDocumentUseCase(repository: built.repository);

      final template = _templateByType(DraftingActType.contratPrestation);
      final request = DraftingRequest(
        mode: DraftingMode.redaction,
        template: template,
        fieldValues: {for (final field in template.requiredFields) field: 'valeur'},
      );

      final initialEvents = await draftUseCase(request).toList();
      final initialResult = initialEvents.whereType<DraftingDoneChunk>().single.result;
      expect(initialResult.content, 'Version initiale du contrat.');

      final adjustmentEvents = await built.repository
          .applyQuickAdjustment(resultId: initialResult.id, adjustment: QuickAdjustment.stricter)
          .toList();
      final adjustedResult = adjustmentEvents.whereType<DraftingDoneChunk>().single.result;

      expect(adjustedResult.id, initialResult.id);
      expect(adjustedResult.content, 'Version renforcée et plus stricte du contrat.');
      expect(built.fakeDataSource.systemPromptsSeen.last, contains('Version initiale du contrat.'));
    });

    test('applyQuickAdjustment lève une erreur pour un identifiant inconnu', () async {
      final built = _buildRepository([]);
      await expectLater(
        built.repository
            .applyQuickAdjustment(resultId: 'inconnu', adjustment: QuickAdjustment.simplifyJargon)
            .toList(),
        throwsArgumentError,
      );
    });
  });

  group('SearchProfessionalPrecedentsUseCase', () {
    test('retrouve les textes de la bibliothèque pour une branche du droit donnée', () {
      final libraryRepository = LibraryRepositoryImpl(dataSource: const LocalLegalDocumentDataSource());
      final useCase = SearchProfessionalPrecedentsUseCase(libraryRepository: libraryRepository);

      final results = useCase(domain: LegalDomain.ohada);

      expect(results, isNotEmpty);
      expect(results.every((doc) => doc.domain == LegalDomain.ohada), isTrue);
      expect(results.map((doc) => doc.title), contains('Acte uniforme relatif au droit commercial général'));
    });

    test('combine mot-clé et domaine', () {
      final libraryRepository = LibraryRepositoryImpl(dataSource: const LocalLegalDocumentDataSource());
      final useCase = SearchProfessionalPrecedentsUseCase(libraryRepository: libraryRepository);

      final results = useCase(keyword: 'licenciement', domain: LegalDomain.travail);

      expect(results.map((doc) => doc.title), contains('Arrêt sur la rupture abusive du contrat de travail'));
    });
  });
}
