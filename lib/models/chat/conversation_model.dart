import 'package:equatable/equatable.dart';

import '../legal_document/legal_domain.dart';
import 'message_model.dart';

/// Espace applicatif dans lequel la conversation a été ouverte.
enum ConversationModule { litigeEtConsultation, espaceProfessionnel }

/// Niveau de complexité estimé du dossier par l'IA.
enum ComplexityLevel { simple, moyenne, complexe }

/// Professionnel du droit vers lequel l'IA peut orienter l'utilisateur à
/// l'issue de son analyse.
enum RecommendedProfessional { avocat, notaire, huissier, mediateur, expert, aucun }

extension RecommendedProfessionalLabel on RecommendedProfessional {
  String get label {
    switch (this) {
      case RecommendedProfessional.avocat:
        return 'Avocat';
      case RecommendedProfessional.notaire:
        return 'Notaire';
      case RecommendedProfessional.huissier:
        return 'Huissier de justice';
      case RecommendedProfessional.mediateur:
        return 'Médiateur';
      case RecommendedProfessional.expert:
        return 'Expert judiciaire';
      case RecommendedProfessional.aucun:
        return 'Aucune orientation nécessaire';
    }
  }
}

/// Grille d'analyse juridique interne suivie par l'IA en arrière-plan pour
/// structurer son raisonnement sur un dossier. Cette grille n'est jamais
/// affichée telle quelle à l'utilisateur : elle nourrit une réponse rédigée
/// naturellement, comme le ferait un juriste expérimenté.
class LegalAnalysisGrid extends Equatable {
  const LegalAnalysisGrid({
    this.faits = '',
    this.qualificationJuridique = '',
    this.droitsEtObligations = '',
    this.textesApplicables = const [],
    this.jurisprudenceApplicable = const [],
    this.elementsDePreuve = const [],
    this.forces = const [],
    this.faiblesses = const [],
    this.chancesDeSucces,
    this.planAction = const [],
    this.professionnelRecommande = RecommendedProfessional.aucun,
    this.justificationRecommandation = '',
    this.isComplete = false,
  });

  final String faits;
  final String qualificationJuridique;
  final String droitsEtObligations;
  final List<String> textesApplicables;
  final List<String> jurisprudenceApplicable;
  final List<String> elementsDePreuve;
  final List<String> forces;
  final List<String> faiblesses;

  /// Estimation en pourcentage (0-100) des chances de succès du dossier.
  final double? chancesDeSucces;

  final List<String> planAction;
  final RecommendedProfessional professionnelRecommande;
  final String justificationRecommandation;

  /// Indique si l'IA dispose de suffisamment d'informations pour considérer
  /// la grille comme exploitable en l'état.
  final bool isComplete;

  LegalAnalysisGrid copyWith({
    String? faits,
    String? qualificationJuridique,
    String? droitsEtObligations,
    List<String>? textesApplicables,
    List<String>? jurisprudenceApplicable,
    List<String>? elementsDePreuve,
    List<String>? forces,
    List<String>? faiblesses,
    double? chancesDeSucces,
    List<String>? planAction,
    RecommendedProfessional? professionnelRecommande,
    String? justificationRecommandation,
    bool? isComplete,
  }) {
    return LegalAnalysisGrid(
      faits: faits ?? this.faits,
      qualificationJuridique: qualificationJuridique ?? this.qualificationJuridique,
      droitsEtObligations: droitsEtObligations ?? this.droitsEtObligations,
      textesApplicables: textesApplicables ?? this.textesApplicables,
      jurisprudenceApplicable: jurisprudenceApplicable ?? this.jurisprudenceApplicable,
      elementsDePreuve: elementsDePreuve ?? this.elementsDePreuve,
      forces: forces ?? this.forces,
      faiblesses: faiblesses ?? this.faiblesses,
      chancesDeSucces: chancesDeSucces ?? this.chancesDeSucces,
      planAction: planAction ?? this.planAction,
      professionnelRecommande: professionnelRecommande ?? this.professionnelRecommande,
      justificationRecommandation: justificationRecommandation ?? this.justificationRecommandation,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'faits': faits,
      'qualificationJuridique': qualificationJuridique,
      'droitsEtObligations': droitsEtObligations,
      'textesApplicables': textesApplicables,
      'jurisprudenceApplicable': jurisprudenceApplicable,
      'elementsDePreuve': elementsDePreuve,
      'forces': forces,
      'faiblesses': faiblesses,
      'chancesDeSucces': chancesDeSucces,
      'planAction': planAction,
      'professionnelRecommande': professionnelRecommande.name,
      'justificationRecommandation': justificationRecommandation,
      'isComplete': isComplete,
    };
  }

  factory LegalAnalysisGrid.fromJson(Map<String, dynamic> json) {
    List<String> stringList(String key) =>
        (json[key] as List<dynamic>? ?? const []).map((e) => e as String).toList();

    return LegalAnalysisGrid(
      faits: json['faits'] as String? ?? '',
      qualificationJuridique: json['qualificationJuridique'] as String? ?? '',
      droitsEtObligations: json['droitsEtObligations'] as String? ?? '',
      textesApplicables: stringList('textesApplicables'),
      jurisprudenceApplicable: stringList('jurisprudenceApplicable'),
      elementsDePreuve: stringList('elementsDePreuve'),
      forces: stringList('forces'),
      faiblesses: stringList('faiblesses'),
      chancesDeSucces: (json['chancesDeSucces'] as num?)?.toDouble(),
      planAction: stringList('planAction'),
      professionnelRecommande: RecommendedProfessional.values.firstWhere(
        (value) => value.name == json['professionnelRecommande'],
        orElse: () => RecommendedProfessional.aucun,
      ),
      justificationRecommandation: json['justificationRecommandation'] as String? ?? '',
      isComplete: json['isComplete'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        faits,
        qualificationJuridique,
        droitsEtObligations,
        textesApplicables,
        jurisprudenceApplicable,
        elementsDePreuve,
        forces,
        faiblesses,
        chancesDeSucces,
        planAction,
        professionnelRecommande,
        justificationRecommandation,
        isComplete,
      ];
}

/// Une conversation entre l'utilisateur et l'IA juridique, qu'elle relève de
/// l'espace "Litiges et consultations" ou de l'"Espace professionnel".
class Conversation extends Equatable {
  const Conversation({
    required this.id,
    required this.title,
    required this.module,
    required this.createdAt,
    required this.updatedAt,
    this.domain,
    this.complexity,
    this.messages = const [],
    this.analysisGrid = const LegalAnalysisGrid(),
    this.isArchived = false,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final ConversationModule module;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Branche du droit identifiée par l'IA. Peut rester nulle tant que l'IA
  /// n'a pas encore assez d'éléments pour la déterminer.
  final LegalDomain? domain;

  final ComplexityLevel? complexity;
  final List<ChatMessage> messages;
  final LegalAnalysisGrid analysisGrid;
  final bool isArchived;
  final bool isFavorite;

  Conversation copyWith({
    String? id,
    String? title,
    ConversationModule? module,
    DateTime? createdAt,
    DateTime? updatedAt,
    LegalDomain? domain,
    ComplexityLevel? complexity,
    List<ChatMessage>? messages,
    LegalAnalysisGrid? analysisGrid,
    bool? isArchived,
    bool? isFavorite,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      module: module ?? this.module,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      domain: domain ?? this.domain,
      complexity: complexity ?? this.complexity,
      messages: messages ?? this.messages,
      analysisGrid: analysisGrid ?? this.analysisGrid,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'module': module.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'domain': domain?.name,
      'complexity': complexity?.name,
      'messages': messages.map((m) => m.toJson()).toList(),
      'analysisGrid': analysisGrid.toJson(),
      'isArchived': isArchived,
      'isFavorite': isFavorite,
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      module: ConversationModule.values.firstWhere(
        (value) => value.name == json['module'],
        orElse: () => ConversationModule.litigeEtConsultation,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      domain: json['domain'] != null ? LegalDomain.fromName(json['domain'] as String) : null,
      complexity: json['complexity'] != null
          ? ComplexityLevel.values.firstWhere(
              (value) => value.name == json['complexity'],
              orElse: () => ComplexityLevel.simple,
            )
          : null,
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      analysisGrid: json['analysisGrid'] != null
          ? LegalAnalysisGrid.fromJson(json['analysisGrid'] as Map<String, dynamic>)
          : const LegalAnalysisGrid(),
      isArchived: json['isArchived'] as bool? ?? false,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        module,
        createdAt,
        updatedAt,
        domain,
        complexity,
        messages,
        analysisGrid,
        isArchived,
        isFavorite,
      ];
}
