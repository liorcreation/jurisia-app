import '../entities/drafting_chunk.dart';
import '../entities/drafting_request.dart';
import '../repositories/professional_repository.dart';

/// Génère un acte personnalisé (contrat, statuts, requête, conclusions,
/// mémoire...) ou une note de synthèse, à partir d'un modèle et des
/// informations fournies par le professionnel.
class DraftLegalDocumentUseCase {
  DraftLegalDocumentUseCase({required this.repository});

  final ProfessionalRepository repository;

  Stream<DraftingChunk> call(DraftingRequest request) => repository.draftDocument(request);
}
