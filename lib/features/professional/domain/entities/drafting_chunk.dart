import 'legal_drafting_result.dart';

/// Événement émis pendant la génération d'un document ou d'un audit par le
/// service IA professionnel : le texte visible au fil de l'eau, puis le
/// résultat complet une fois la génération terminée.
sealed class DraftingChunk {
  const DraftingChunk();
}

class DraftingTextDeltaChunk extends DraftingChunk {
  const DraftingTextDeltaChunk(this.delta);

  final String delta;
}

class DraftingDoneChunk extends DraftingChunk {
  const DraftingDoneChunk(this.result);

  final LegalDraftingResult result;
}
