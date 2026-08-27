import '../repositories/litigation_repository.dart';

/// Résume le premier message d'une consultation en un titre court pour
/// l'historique — voir [LitigationRepository.generateTitle].
class GenerateConversationTitleUseCase {
  const GenerateConversationTitleUseCase({required this.repository});

  final LitigationRepository repository;

  Future<String> call(String firstMessage) => repository.generateTitle(firstMessage);
}
