import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/ai_thinking_indicator.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/luxury_elevated_button.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/student_level.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/evaluation_controller.dart';
import '../controllers/student_controller.dart';

/// Écran d'évaluation de fin de module : quiz interactif (QCM et cas
/// pratiques), calcul de la note sur 20, déblocage du module suivant en cas
/// de réussite, invitation à reprendre avec de nouvelles questions sinon.
class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context) {
    final studentController = context.read<StudentController>();

    return ChangeNotifierProvider<EvaluationController>(
      create: (_) => EvaluationController(
        moduleId: moduleId,
        generateUseCase: studentController.generateEvaluationUseCase,
        validateUseCase: studentController.validateModuleUseCase,
        repository: studentController.repository,
      ),
      child: const _EvaluationView(),
    );
  }
}

class _EvaluationView extends StatelessWidget {
  const _EvaluationView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EvaluationController>();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Évaluation du module')),
        body: SafeArea(child: _buildBody(context, controller)),
      ),
    );
  }

  Widget _buildBody(BuildContext context, EvaluationController controller) {
    if (controller.status == EvaluationLoadStatus.loading) {
      return const _LoadingState();
    }
    if (controller.status == EvaluationLoadStatus.error) {
      return _ErrorState(
        message: controller.errorMessage ?? 'Une erreur est survenue.',
        onRetry: controller.retryWithNewQuestions,
      );
    }
    if (controller.isSubmitted) {
      return _ResultState(controller: controller);
    }
    return _EvaluationForm(controller: controller);
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: AiThinkingIndicator(label: "Préparation de l'évaluation…"));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}

class _EvaluationForm extends StatefulWidget {
  const _EvaluationForm({required this.controller});

  final EvaluationController controller;

  @override
  State<_EvaluationForm> createState() => _EvaluationFormState();
}

class _EvaluationFormState extends State<_EvaluationForm> {
  final Map<String, TextEditingController> _textControllers = {};

  TextEditingController _controllerFor(String questionId) {
    return _textControllers.putIfAbsent(questionId, () => TextEditingController());
  }

  @override
  void dispose() {
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = widget.controller.evaluation!;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Tentative n° ${evaluation.attemptNumber}', style: textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Répondez aux ${evaluation.questions.length} questions ci-dessous. Une moyenne de '
                '10/20 débloque le module suivant.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < evaluation.questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _QuestionCard(
                    index: i + 1,
                    question: evaluation.questions[i],
                    controller: widget.controller,
                    textController: evaluation.questions[i].type == QuestionType.casPratique
                        ? _controllerFor(evaluation.questions[i].id)
                        : null,
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: LuxuryElevatedButton(
            onPressed: widget.controller.allQuestionsAnswered ? widget.controller.submit : null,
            child: const Text('Valider mes réponses'),
          ),
        ),
      ],
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.controller,
    required this.textController,
  });

  final int index;
  final EvaluationQuestion question;
  final EvaluationController controller;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  'Q$index',
                  style: textTheme.labelSmall?.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(question.statement, style: textTheme.bodyLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (question.type == QuestionType.qcm)
            _QcmOptions(question: question, controller: controller)
          else
            TextField(
              controller: textController,
              maxLines: 4,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: 'Votre réponse…'),
              onChanged: (value) => controller.answerCasPratique(question.id, value),
            ),
        ],
      ),
    );
  }
}

class _QcmOptions extends StatelessWidget {
  const _QcmOptions({required this.question, required this.controller});

  final EvaluationQuestion question;
  final EvaluationController controller;

  @override
  Widget build(BuildContext context) {
    final selected = controller.answerFor(question.id);

    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: _OptionTile(
              label: question.options[i],
              isSelected: selected == i.toString(),
              onTap: () => controller.answerQcm(question.id, i),
            ),
          ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.gold.withValues(alpha: 0.14) : AppColors.legalBlueDark.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultState extends StatelessWidget {
  const _ResultState({required this.controller});

  final EvaluationController controller;

  @override
  Widget build(BuildContext context) {
    final result = controller.result!;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ResultBadge(passed: result.passed),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '${result.score.toStringAsFixed(1)} / 20',
              style: textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.passed ? 'Module validé !' : 'Pas encore suffisant',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.passed
                  ? (result.unlockedNextModuleId != null
                      ? 'Le module suivant est désormais débloqué.'
                      : 'Vous avez validé le dernier module de ce niveau.')
                  : 'La moyenne requise est de 10/20. Reprenez avec un nouveau jeu de questions dès que vous êtes prêt.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium,
            ),
            if (result.levelCompleted && result.unlockedNextLevel != null) ...[
              const SizedBox(height: AppSpacing.sm),
              GlassContainer(
                borderColor: AppColors.gold,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.emoji_events_rounded, color: AppColors.gold),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        'Niveau entièrement validé : ${result.unlockedNextLevel!.fullLabel} est débloqué !',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (result.passed)
              LuxuryElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Retour au module'),
              )
            else
              Column(
                children: [
                  LuxuryElevatedButton(
                    onPressed: controller.retryWithNewQuestions,
                    child: const Text('Reprendre avec de nouvelles questions'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Retour au module'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.passed});

  final bool passed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.scale(scale: value, child: child),
        );
      },
      child: Container(
        width: 96,
        height: 96,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: passed ? AppGradients.goldMetallic : null,
          color: passed ? null : AppColors.legalBlueDark,
          shape: BoxShape.circle,
          border: passed ? null : Border.all(color: AppColors.error, width: 2),
        ),
        child: Icon(
          passed ? Icons.emoji_events_rounded : Icons.refresh_rounded,
          size: 48,
          color: passed ? AppColors.nightBlueDeep : AppColors.error,
        ),
      ),
    );
  }
}
