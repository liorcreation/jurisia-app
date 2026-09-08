import 'dart:convert';

import '../../../../core/ai/groq_api_datasource.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../domain/usecases/grade_evaluation_usecase.dart';

/// Note assistée par IA d'une réponse rédigée (cas pratique), utilisée par
/// les modes écrit et oral de l'examen blanc. Sur tout échec (réseau, IA non
/// configurée, sortie invalide), se replie sur l'heuristique de
/// correspondance de mots-clés déjà utilisée par [GradeEvaluationUseCase] —
/// jamais de blocage de la correction pour une raison d'infrastructure.
class AiAnswerGrader {
  AiAnswerGrader({required this.dataSource, GradeEvaluationUseCase? fallback})
      : _fallback = fallback ?? const GradeEvaluationUseCase();

  final LlmDataSource dataSource;
  final GradeEvaluationUseCase _fallback;

  /// Renvoie la fraction de points obtenue (0 à 1) et une courte
  /// justification pédagogique.
  Future<({double fraction, String justification})> grade(EvaluationQuestion question) async {
    final answer = (question.studentAnswer ?? '').trim();
    if (answer.isEmpty) return (fraction: 0.0, justification: 'Aucune réponse fournie.');

    try {
      final buffer = StringBuffer();
      await for (final chunk in dataSource.streamCompletion(
        system: _systemPrompt(question),
        messages: [
          {'role': 'user', 'content': answer},
        ],
        maxTokens: 512,
      )) {
        buffer.write(chunk);
      }
      return _parse(buffer.toString());
    } catch (_) {
      final awarded = _fallback([question.copyWith(points: 1)]);
      return (fraction: awarded.clamp(0.0, 1.0), justification: 'Correction automatique (mots-clés).');
    }
  }

  String _systemPrompt(EvaluationQuestion question) {
    return '''
Tu es un correcteur académique de droit. Voici la question posée et les éléments de réponse attendus :

Question : ${question.statement}
Éléments attendus : ${question.expectedAnswerElements.join(', ')}

Note la réponse de l'étudiant (fournie dans le message suivant) par rapport à ces éléments attendus, en tenant compte de la pertinence juridique globale, pas seulement de la présence littérale des mots-clés.

Réponds UNIQUEMENT avec un objet JSON strictement valide, sans texte avant ou après, sur le modèle exact suivant :
{"fraction":0.75,"justification":"Explication courte de la note attribuée."}

"fraction" est un nombre entre 0 et 1 (part des points obtenus).
''';
  }

  ({double fraction, String justification}) _parse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start == -1 || end == -1 || end < start) {
      throw const FormatException("Réponse de l'IA sans objet JSON exploitable.");
    }
    final decoded = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
    final fraction = (decoded['fraction'] as num?)?.toDouble();
    if (fraction == null) {
      throw const FormatException('Fraction de notation manquante.');
    }
    return (
      fraction: fraction.clamp(0.0, 1.0),
      justification: decoded['justification'] as String? ?? '',
    );
  }
}
