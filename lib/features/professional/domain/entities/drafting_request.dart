import '../../../../models/legal_document/legal_domain.dart';
import 'professional_template.dart';

/// Les trois modes de travail de l'Espace professionnel.
enum DraftingMode { redaction, audit, consultation }

/// Requête adressée au service IA professionnel : rédaction d'un acte à
/// partir d'un modèle, audit d'un contrat existant, ou consultation
/// approfondie sur une question de droit.
class DraftingRequest {
  const DraftingRequest({
    required this.mode,
    this.template,
    this.fieldValues = const {},
    this.instructions = '',
    this.contractText,
    this.domainHint,
  });

  final DraftingMode mode;

  /// Modèle d'acte choisi, requis en mode [DraftingMode.redaction].
  final ProfessionalTemplate? template;

  /// Valeurs saisies pour chacun des [ProfessionalTemplate.requiredFields],
  /// requises en mode [DraftingMode.redaction].
  final Map<String, String> fieldValues;

  /// Instructions complémentaires (rédaction), points de vigilance (audit),
  /// ou la question elle-même (consultation).
  final String instructions;

  /// Texte du contrat à auditer, requis en mode [DraftingMode.audit].
  final String? contractText;

  /// Branche du droit à privilégier pour enrichir le contexte depuis la
  /// bibliothèque juridique (audit et consultation ; dérivée du modèle en
  /// mode rédaction).
  final LegalDomain? domainHint;
}
