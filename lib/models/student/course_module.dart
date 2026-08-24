import 'package:equatable/equatable.dart';

import '../legal_document/legal_domain.dart';
import 'student_level.dart';

/// Une leçon appartenant à un [CourseModule] : cours complet avec
/// explications pédagogiques.
class Lesson extends Equatable {
  const Lesson({
    required this.id,
    required this.moduleId,
    required this.order,
    required this.title,
    required this.content,
    this.estimatedMinutes = 20,
  });

  final String id;
  final String moduleId;
  final int order;
  final String title;
  final String content;
  final int estimatedMinutes;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'order': order,
      'title': title,
      'content': content,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      order: json['order'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 20,
    );
  }

  @override
  List<Object?> get props => [id, moduleId, order, title, content, estimatedMinutes];
}

/// Une fiche de révision synthétique associée à un module.
class RevisionSheet extends Equatable {
  const RevisionSheet({
    required this.id,
    required this.moduleId,
    required this.title,
    required this.keyPoints,
  });

  final String id;
  final String moduleId;
  final String title;
  final List<String> keyPoints;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'title': title,
      'keyPoints': keyPoints,
    };
  }

  factory RevisionSheet.fromJson(Map<String, dynamic> json) {
    return RevisionSheet(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      title: json['title'] as String,
      keyPoints: (json['keyPoints'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
    );
  }

  @override
  List<Object?> get props => [id, moduleId, title, keyPoints];
}

/// Un exercice pratique proposé au sein d'un module.
class Exercise extends Equatable {
  const Exercise({
    required this.id,
    required this.moduleId,
    required this.statement,
    required this.correctionGuideline,
    this.difficulty = 1,
  });

  final String id;
  final String moduleId;
  final String statement;
  final String correctionGuideline;

  /// Niveau de difficulté de 1 (facile) à 5 (très difficile).
  final int difficulty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moduleId': moduleId,
      'statement': statement,
      'correctionGuideline': correctionGuideline,
      'difficulty': difficulty,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      moduleId: json['moduleId'] as String,
      statement: json['statement'] as String,
      correctionGuideline: json['correctionGuideline'] as String,
      difficulty: json['difficulty'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, moduleId, statement, correctionGuideline, difficulty];
}

/// Un module du parcours universitaire officiel et séquentiel d'un niveau
/// donné. Seul le premier module d'un niveau est débloqué par défaut ; les
/// suivants se débloquent après réussite de l'évaluation du module précédent.
class CourseModule extends Equatable {
  const CourseModule({
    required this.id,
    required this.level,
    required this.order,
    required this.title,
    required this.description,
    required this.domain,
    this.lessons = const [],
    this.revisionSheets = const [],
    this.exercises = const [],
    this.isUnlocked = false,
    this.isCompleted = false,
    this.lastScore,
  });

  final String id;
  final AcademicLevel level;

  /// Position séquentielle du module au sein du niveau (1 = premier module).
  final int order;

  final String title;
  final String description;
  final LegalDomain domain;
  final List<Lesson> lessons;
  final List<RevisionSheet> revisionSheets;
  final List<Exercise> exercises;
  final bool isUnlocked;
  final bool isCompleted;

  /// Meilleure note obtenue (sur 20) à l'évaluation de ce module, ou `null`
  /// si aucune tentative n'a encore été corrigée.
  final double? lastScore;

  CourseModule copyWith({
    String? id,
    AcademicLevel? level,
    int? order,
    String? title,
    String? description,
    LegalDomain? domain,
    List<Lesson>? lessons,
    List<RevisionSheet>? revisionSheets,
    List<Exercise>? exercises,
    bool? isUnlocked,
    bool? isCompleted,
    double? lastScore,
  }) {
    return CourseModule(
      id: id ?? this.id,
      level: level ?? this.level,
      order: order ?? this.order,
      title: title ?? this.title,
      description: description ?? this.description,
      domain: domain ?? this.domain,
      lessons: lessons ?? this.lessons,
      revisionSheets: revisionSheets ?? this.revisionSheets,
      exercises: exercises ?? this.exercises,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      lastScore: lastScore ?? this.lastScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level': level.name,
      'order': order,
      'title': title,
      'description': description,
      'domain': domain.name,
      'lessons': lessons.map((l) => l.toJson()).toList(),
      'revisionSheets': revisionSheets.map((r) => r.toJson()).toList(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'isUnlocked': isUnlocked,
      'isCompleted': isCompleted,
      'lastScore': lastScore,
    };
  }

  factory CourseModule.fromJson(Map<String, dynamic> json) {
    return CourseModule(
      id: json['id'] as String,
      level: AcademicLevelLabel.fromName(json['level'] as String),
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      domain: LegalDomain.fromName(json['domain'] as String),
      lessons: (json['lessons'] as List<dynamic>? ?? const [])
          .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
          .toList(),
      revisionSheets: (json['revisionSheets'] as List<dynamic>? ?? const [])
          .map((r) => RevisionSheet.fromJson(r as Map<String, dynamic>))
          .toList(),
      exercises: (json['exercises'] as List<dynamic>? ?? const [])
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      lastScore: (json['lastScore'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        level,
        order,
        title,
        description,
        domain,
        lessons,
        revisionSheets,
        exercises,
        isUnlocked,
        isCompleted,
        lastScore,
      ];
}
