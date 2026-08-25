import 'dart:convert';

import 'package:uuid/uuid.dart';

import '../../../../core/ai/groq_api_datasource.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import 'student_ai_prompts.dart';

/// Génère un jeu de questions d'évaluation via l'IA, en exigeant une sortie
/// strictement JSON. Toute réponse invalide ou tout échec réseau doit être
/// intercepté par l'appelant, qui se replie alors sur la banque de
/// questions locale.
class AiEvaluationGenerator {
  AiEvaluationGenerator({required this.dataSource, Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final LlmDataSource dataSource;
  final Uuid _uuid;

  Future<List<EvaluationQuestion>> generate({
    required CourseModule module,
    required int questionCount,
  }) async {
    final buffer = StringBuffer();
    await for (final chunk in dataSource.streamCompletion(
      system: StudentAiPrompts.evaluationGeneratorSystemPrompt(module, questionCount),
      messages: const [
        {'role': 'user', 'content': 'Génère les questions au format demandé.'},
      ],
      maxTokens: 2048,
    )) {
      buffer.write(chunk);
    }
    return _parseQuestions(buffer.toString());
  }

  List<EvaluationQuestion> _parseQuestions(String raw) {
    final start = raw.indexOf('[');
    final end = raw.lastIndexOf(']');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException("Réponse de l'IA sans tableau JSON exploitable.");
    }

    final decoded = jsonDecode(raw.substring(start, end + 1));
    if (decoded is! List) {
      throw const FormatException("Le tableau de questions généré par l'IA est invalide.");
    }

    final questions = decoded.map((item) {
      final map = item as Map<String, dynamic>;
      final isCasPratique = map['type'] == 'casPratique';

      return EvaluationQuestion(
        id: _uuid.v4(),
        type: isCasPratique ? QuestionType.casPratique : QuestionType.qcm,
        statement: map['statement'] as String,
        points: (map['points'] as num?)?.toDouble() ?? 5,
        options: (map['options'] as List<dynamic>? ?? const []).map((e) => e as String).toList(),
        correctOptionIndex: map['correctOptionIndex'] as int?,
        expectedAnswerElements: (map['expectedAnswerElements'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
        explanation: map['explanation'] as String? ?? '',
      );
    }).toList();

    if (questions.isEmpty) {
      throw const FormatException("L'IA n'a généré aucune question exploitable.");
    }

    return questions;
  }
}
