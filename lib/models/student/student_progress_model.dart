import 'package:equatable/equatable.dart';

import 'evaluation_model.dart';
import 'student_level.dart';

/// Suivi de progression d'un étudiant sur un module donné : statut de
/// déblocage, meilleure note obtenue et historique des tentatives
/// d'évaluation.
class ModuleProgress extends Equatable {
  const ModuleProgress({
    required this.moduleId,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestScore,
    this.attempts = const [],
    this.lastAccessedAt,
  });

  final String moduleId;
  final bool isUnlocked;
  final bool isCompleted;
  final double? bestScore;
  final List<ModuleEvaluation> attempts;
  final DateTime? lastAccessedAt;

  /// Pourcentage de réussite basé sur la meilleure note obtenue.
  double get bestPercentage => bestScore == null ? 0 : (bestScore! / 20) * 100;

  ModuleProgress copyWith({
    String? moduleId,
    bool? isUnlocked,
    bool? isCompleted,
    double? bestScore,
    List<ModuleEvaluation>? attempts,
    DateTime? lastAccessedAt,
  }) {
    return ModuleProgress(
      moduleId: moduleId ?? this.moduleId,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestScore: bestScore ?? this.bestScore,
      attempts: attempts ?? this.attempts,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleId': moduleId,
      'isUnlocked': isUnlocked,
      'isCompleted': isCompleted,
      'bestScore': bestScore,
      'attempts': attempts.map((a) => a.toJson()).toList(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
    };
  }

  factory ModuleProgress.fromJson(Map<String, dynamic> json) {
    return ModuleProgress(
      moduleId: json['moduleId'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? false,
      bestScore: (json['bestScore'] as num?)?.toDouble(),
      attempts: (json['attempts'] as List<dynamic>? ?? const [])
          .map((a) => ModuleEvaluation.fromJson(a as Map<String, dynamic>))
          .toList(),
      lastAccessedAt:
          json['lastAccessedAt'] != null ? DateTime.parse(json['lastAccessedAt'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [moduleId, isUnlocked, isCompleted, bestScore, attempts, lastAccessedAt];
}

/// Progression globale d'un étudiant dans son parcours universitaire
/// JurisIA : niveau choisi et avancement module par module.
class StudentProgress extends Equatable {
  const StudentProgress({
    required this.studentId,
    required this.level,
    this.moduleProgress = const {},
    this.levelSelectedAt,
  });

  final String studentId;
  final AcademicLevel level;

  /// Progression indexée par identifiant de module.
  final Map<String, ModuleProgress> moduleProgress;

  final DateTime? levelSelectedAt;

  /// Nombre de modules validés (moyenne ≥ 10/20) sur ce niveau.
  int get completedModulesCount =>
      moduleProgress.values.where((progress) => progress.isCompleted).length;

  /// Identifiants des modules validés (moyenne ≥ 10/20) sur ce niveau.
  List<String> get validatedModuleIds => moduleProgress.values
      .where((progress) => progress.isCompleted)
      .map((progress) => progress.moduleId)
      .toList();

  /// Moyenne générale de l'étudiant sur l'ensemble des modules déjà notés.
  double get overallAverage {
    final scored = moduleProgress.values.where((p) => p.bestScore != null).toList();
    if (scored.isEmpty) return 0;
    final total = scored.fold<double>(0, (sum, p) => sum + p.bestScore!);
    return total / scored.length;
  }

  /// Pourcentage de progression du niveau, calculé par rapport au nombre
  /// total de modules que compte ce niveau.
  double progressPercentage(int totalModulesInLevel) {
    if (totalModulesInLevel <= 0) return 0;
    return (completedModulesCount / totalModulesInLevel) * 100;
  }

  StudentProgress copyWith({
    String? studentId,
    AcademicLevel? level,
    Map<String, ModuleProgress>? moduleProgress,
    DateTime? levelSelectedAt,
  }) {
    return StudentProgress(
      studentId: studentId ?? this.studentId,
      level: level ?? this.level,
      moduleProgress: moduleProgress ?? this.moduleProgress,
      levelSelectedAt: levelSelectedAt ?? this.levelSelectedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'level': level.name,
      'moduleProgress': moduleProgress.map((key, value) => MapEntry(key, value.toJson())),
      'levelSelectedAt': levelSelectedAt?.toIso8601String(),
    };
  }

  factory StudentProgress.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['moduleProgress'] as Map<String, dynamic>? ?? const {};
    return StudentProgress(
      studentId: json['studentId'] as String,
      level: AcademicLevelLabel.fromName(json['level'] as String),
      moduleProgress: rawProgress.map(
        (key, value) => MapEntry(key, ModuleProgress.fromJson(value as Map<String, dynamic>)),
      ),
      levelSelectedAt:
          json['levelSelectedAt'] != null ? DateTime.parse(json['levelSelectedAt'] as String) : null,
    );
  }

  @override
  List<Object?> get props => [studentId, level, moduleProgress, levelSelectedAt];
}
