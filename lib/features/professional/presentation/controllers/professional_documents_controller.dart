import 'package:flutter/foundation.dart';

import '../../domain/entities/legal_drafting_result.dart';
import '../../domain/repositories/professional_repository.dart';

/// État léger de la liste des documents déjà générés — alimente la section
/// « Documents récents » de la sidebar. L'écran professionnel construit
/// toujours son propre [DraftingWorkspaceController] par requête ; ce
/// contrôleur ne fait que lire ce que [ProfessionalRepository.hydrate] a
/// chargé.
class ProfessionalDocumentsController extends ChangeNotifier {
  ProfessionalDocumentsController({required this.repository}) {
    repository.hydrate().then((_) => notifyListeners());
  }

  final ProfessionalRepository repository;

  List<LegalDraftingResult> get recentResults => repository.recentResults;

  void refresh() => notifyListeners();
}
