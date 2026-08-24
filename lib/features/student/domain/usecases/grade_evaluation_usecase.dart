import '../../../../models/student/evaluation_model.dart';

/// Calcule la note obtenue (sur le total des points des questions fournies,
/// 20 par convention) à partir des réponses de l'étudiant : correspondance
/// exacte pour un QCM, score proportionnel aux éléments de réponse attendus
/// retrouvés dans la réponse rédigée pour un cas pratique.
class GradeEvaluationUseCase {
  const GradeEvaluationUseCase();

  double call(List<EvaluationQuestion> answeredQuestions) {
    var total = 0.0;
    for (final question in answeredQuestions) {
      total += _scoreQuestion(question);
    }
    return total;
  }

  double _scoreQuestion(EvaluationQuestion question) {
    if (question.type == QuestionType.qcm) {
      final answerIndex = int.tryParse(question.studentAnswer ?? '');
      final isCorrect = answerIndex != null && answerIndex == question.correctOptionIndex;
      return isCorrect ? question.points : 0;
    }

    final answer = (question.studentAnswer ?? '').trim().toLowerCase();
    if (answer.isEmpty || question.expectedAnswerElements.isEmpty) return 0;

    final matched = question.expectedAnswerElements
        .where((element) => answer.contains(element.toLowerCase()))
        .length;
    return question.points * (matched / question.expectedAnswerElements.length);
  }
}
