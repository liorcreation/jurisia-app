import '../entities/drafting_chunk.dart';
import '../entities/drafting_request.dart';
import '../repositories/professional_repository.dart';

/// Audite un contrat fourni par le professionnel et détecte les clauses
/// abusives ou à risque, avec des propositions de reformulation.
class AnalyzeContractUseCase {
  AnalyzeContractUseCase({required this.repository});

  final ProfessionalRepository repository;

  Stream<DraftingChunk> call(DraftingRequest request) => repository.analyzeContract(request);
}
