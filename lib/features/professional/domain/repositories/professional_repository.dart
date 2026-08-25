import '../entities/drafting_chunk.dart';
import '../entities/drafting_request.dart';
import '../entities/legal_drafting_result.dart';
import '../entities/professional_template.dart';
import '../entities/quick_adjustment.dart';

/// Frontière du domaine vers le service IA professionnel : rédaction
/// d'actes, audit de contrats et ajustements rapides, enrichis par le
/// contexte de la bibliothèque juridique.
abstract class ProfessionalRepository {
  /// Modèles d'actes proposés en rédaction rapide.
  List<ProfessionalTemplate> get templates;

  /// Rédige un acte ([DraftingMode.redaction]) ou une note de synthèse
  /// ([DraftingMode.consultation]) selon le mode de la requête.
  Stream<DraftingChunk> draftDocument(DraftingRequest request);

  /// Audite un contrat existant ([DraftingMode.audit]) et identifie ses
  /// clauses à risque.
  Stream<DraftingChunk> analyzeContract(DraftingRequest request);

  /// Applique un ajustement rapide au document déjà généré.
  Stream<DraftingChunk> applyQuickAdjustment({
    required String resultId,
    required QuickAdjustment adjustment,
  });

  LegalDraftingResult? findResult(String resultId);

  LegalDraftingResult toggleFavorite(String resultId);

  /// Charge les résultats déjà connus d'une source de persistance avant la
  /// première consultation. Sans effet par défaut.
  Future<void> hydrate() async {}

  void dispose();
}
