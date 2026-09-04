import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
import '../../../../core/widgets/jurisia_mark.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/student/course_module.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/student_level.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/evaluation_controller.dart';
import '../controllers/student_controller.dart';

/// Écran d'évaluation de fin de module : quiz interactif (QCM et cas
/// pratiques), calcul de la note sur 20, déblocage du module suivant en cas
/// de réussite, invitation à reprendre avec de nouvelles questions sinon.
class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({super.key, required this.moduleId, this.controllerOverride});

  final String moduleId;

  /// Contrôleur injecté (aperçus / tests). En production, l'écran construit
  /// le sien à partir du [StudentController] de la coquille.
  final EvaluationController? controllerOverride;

  @override
  Widget build(BuildContext context) {
    final studentController = context.read<StudentController>();

    return ChangeNotifierProvider<EvaluationController>(
      create: (_) =>
          controllerOverride ??
          EvaluationController(
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
    final module = context.read<StudentController>().repository.findModule(controller.moduleId);
    return _DesktopEvaluationView(controller: controller, module: module);
  }
}
// ===========================================================================
//  DESKTOP — « L'épreuve »
// ===========================================================================

/// Note obtenue et justesse d'une question, recalculées pour l'affichage de
/// la copie corrigée (le barème n'est pas persisté par question).
({double awarded, _Verdict verdict}) _gradeQuestion(EvaluationQuestion q) {
  if (q.type == QuestionType.qcm) {
    final idx = int.tryParse(q.studentAnswer ?? '');
    final correct = idx != null && idx == q.correctOptionIndex;
    return (awarded: correct ? q.points : 0, verdict: correct ? _Verdict.correct : _Verdict.wrong);
  }
  final answer = (q.studentAnswer ?? '').trim().toLowerCase();
  if (answer.isEmpty || q.expectedAnswerElements.isEmpty) {
    return (awarded: 0, verdict: _Verdict.wrong);
  }
  final matched =
      q.expectedAnswerElements.where((e) => answer.contains(e.toLowerCase())).length;
  final awarded = q.points * (matched / q.expectedAnswerElements.length);
  final verdict = matched == q.expectedAnswerElements.length
      ? _Verdict.correct
      : matched == 0
          ? _Verdict.wrong
          : _Verdict.partial;
  return (awarded: awarded, verdict: verdict);
}

enum _Verdict { correct, partial, wrong }

extension _VerdictStyle on _Verdict {
  Color get color => switch (this) {
        _Verdict.correct => AppColors.success,
        _Verdict.partial => AppColors.warning,
        _Verdict.wrong => AppColors.error,
      };
  IconData get icon => switch (this) {
        _Verdict.correct => Icons.check_circle_rounded,
        _Verdict.partial => Icons.adjust_rounded,
        _Verdict.wrong => Icons.cancel_rounded,
      };
  String get label => switch (this) {
        _Verdict.correct => 'Juste',
        _Verdict.partial => 'Partiel',
        _Verdict.wrong => 'À revoir',
      };
}

String _typeLabel(QuestionType t) => t == QuestionType.qcm ? 'QCM' : 'Cas pratique';

class _DesktopEvaluationView extends StatelessWidget {
  const _DesktopEvaluationView({required this.controller, required this.module});

  final EvaluationController controller;
  final CourseModule? module;

  @override
  Widget build(BuildContext context) {
    final Widget body;
    if (controller.status == EvaluationLoadStatus.loading) {
      body = _DesktopLoading(module: module);
    } else if (controller.status == EvaluationLoadStatus.error) {
      body = _DesktopError(
        message: controller.errorMessage ?? 'Une erreur est survenue.',
        onRetry: controller.retryWithNewQuestions,
      );
    } else if (controller.isSubmitted) {
      body = _DesktopResult(controller: controller, module: module);
    } else {
      body = _DesktopEvalForm(controller: controller);
    }

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: _EvalAmbience())),
              Column(
                children: [
                  _DesktopEvalHeader(module: module, controller: controller),
                  Expanded(child: body),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopEvalHeader extends StatelessWidget {
  const _DesktopEvalHeader({required this.module, required this.controller});

  final CourseModule? module;
  final EvaluationController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final attempt = controller.evaluation?.attemptNumber;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.sm,
        compact ? AppSpacing.sm : AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quitter l\'évaluation',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          if (!compact) ...[
            const SizedBox(width: AppSpacing.xs),
            const Icon(Icons.fact_check_rounded, size: 18, color: AppColors.gold),
          ],
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? 'Évaluation' : 'Évaluation du module',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display')
                      : textTheme.headlineSmall,
                ),
                if (module != null)
                  Text(
                    module!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                  ),
              ],
            ),
          ),
          if (attempt != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.28), width: 0.7),
              ),
              child: Text(
                compact ? 'N° $attempt' : 'Tentative n° $attempt',
                style: textTheme.labelSmall?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  États : préparation / erreur
// ---------------------------------------------------------------------------

class _DesktopLoading extends StatelessWidget {
  const _DesktopLoading({required this.module});

  final CourseModule? module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingMark(),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Préparation de votre épreuve',
            style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              module == null
                  ? 'L\'IA compose un jeu de questions inédit.'
                  : 'L\'IA compose un jeu de questions inédit à partir du module « ${module!.title} ».',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingMark extends StatefulWidget {
  @override
  State<_PulsingMark> createState() => _PulsingMarkState();
}

class _PulsingMarkState extends State<_PulsingMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        return Container(
          width: 92,
          height: 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.10 + 0.22 * t),
                blurRadius: 24 + 16 * t,
                spreadRadius: 2 + 4 * t,
              ),
            ],
          ),
          child: Opacity(opacity: 0.7 + 0.3 * t, child: const JurisIAMark(size: 52)),
        );
      },
    );
  }
}

class _DesktopError extends StatelessWidget {
  const _DesktopError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderColor: AppColors.error.withValues(alpha: 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 36),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.nightBlueDeep,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Le formulaire (deux colonnes)
// ---------------------------------------------------------------------------

class _DesktopEvalForm extends StatefulWidget {
  const _DesktopEvalForm({required this.controller});

  final EvaluationController controller;

  @override
  State<_DesktopEvalForm> createState() => _DesktopEvalFormState();
}

class _DesktopEvalFormState extends State<_DesktopEvalForm> {
  final ScrollController _scroll = ScrollController();
  final Map<String, TextEditingController> _textControllers = {};
  late final List<GlobalKey> _keys;

  TextEditingController _controllerFor(String id) =>
      _textControllers.putIfAbsent(id, () => TextEditingController());

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.controller.evaluation!.questions.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    for (final c in _textControllers.values) {
      c.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(int index) {
    final ctx = _keys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 320),
      curve: Curves.fastOutSlowIn,
      alignment: 0.08,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final evaluation = controller.evaluation!;
    final questions = evaluation.questions;
    final answered = [
      for (final q in questions) (controller.answerFor(q.id) ?? '').trim().isNotEmpty,
    ];
    final answeredCount = answered.where((e) => e).length;
    final totalPoints = questions.fold<double>(0, (s, q) => s + q.points);

    final navigator = _QuestionNavigator(
      attempt: evaluation.attemptNumber,
      answered: answered,
      answeredCount: answeredCount,
      total: questions.length,
      totalPoints: totalPoints,
      canSubmit: controller.allQuestionsAnswered,
      onSubmit: controller.submit,
      onJump: _scrollTo,
    );

    final compact = MediaQuery.sizeOf(context).width < 600;
    final scroller = SingleChildScrollView(
      controller: _scroll,
      padding: EdgeInsets.fromLTRB(
        compact ? AppSpacing.lg : AppSpacing.xl,
        compact ? AppSpacing.lg : AppSpacing.xl,
        compact ? AppSpacing.lg : AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Eyebrow('L\'épreuve'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Composez votre copie',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Répondez aux ${questions.length} questions. Une moyenne de 10/20 valide le '
                'module et débloque le suivant.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(width: 54, height: 2, color: AppColors.gold.withValues(alpha: 0.7)),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < questions.length; i++)
                KeyedSubtree(
                  key: _keys[i],
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: i == questions.length - 1 ? 0 : AppSpacing.lg,
                    ),
                    child: EntranceFadeSlide(
                      index: i,
                      child: _DesktopQuestionCard(
                        index: i + 1,
                        question: questions[i],
                        controller: controller,
                        textController: questions[i].type == QuestionType.casPratique
                            ? _controllerFor(questions[i].id)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1080;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 300, child: navigator),
              Expanded(child: scroller),
            ],
          );
        }
        // Compact : le navigateur de questions laisse place à une barre
        // basse (progression + validation).
        return Column(
          children: [
            Expanded(child: scroller),
            _MobileEvalBar(
              answeredCount: answeredCount,
              total: questions.length,
              canSubmit: controller.allQuestionsAnswered,
              onSubmit: controller.submit,
            ),
          ],
        );
      },
    );
  }
}

class _MobileEvalBar extends StatelessWidget {
  const _MobileEvalBar({
    required this.answeredCount,
    required this.total,
    required this.canSubmit,
    required this.onSubmit,
  });

  final int answeredCount;
  final int total;
  final bool canSubmit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : answeredCount / total;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(
          top: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '$answeredCount / $total répondue${answeredCount > 1 ? 's' : ''}',
                  style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
                ),
                const Spacer(),
                if (!canSubmit)
                  Text(
                    'Répondez à tout pour valider',
                    style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  Container(height: 5, color: AppColors.legalBlueDark),
                  FractionallySizedBox(
                    widthFactor: fraction <= 0 ? 0.001 : fraction,
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(gradient: AppGradients.goldMetallic),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.nightBlueDeep,
                disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.18),
                disabledForegroundColor: AppColors.textDisabled,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 17),
              label: const Text('Valider mes réponses'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionNavigator extends StatelessWidget {
  const _QuestionNavigator({
    required this.attempt,
    required this.answered,
    required this.answeredCount,
    required this.total,
    required this.totalPoints,
    required this.canSubmit,
    required this.onSubmit,
    required this.onJump,
  });

  final int attempt;
  final List<bool> answered;
  final int answeredCount;
  final int total;
  final double totalPoints;
  final bool canSubmit;
  final VoidCallback onSubmit;
  final ValueChanged<int> onJump;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : answeredCount / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.sm, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Eyebrow('Progression'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < total; i++)
                _NavPill(number: i + 1, answered: answered[i], onTap: () => onJump(i)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          RichText(
            text: TextSpan(
              style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display'),
              children: [
                TextSpan(text: '$answeredCount'),
                TextSpan(
                  text: ' / $total répondu${answeredCount > 1 ? 'es' : 'e'}',
                  style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.legalBlueDark),
                FractionallySizedBox(
                  widthFactor: fraction <= 0 ? 0.001 : fraction,
                  child: Container(
                    height: 6,
                    decoration: const BoxDecoration(gradient: AppGradients.goldMetallic),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _NavRow(icon: Icons.flag_rounded, text: 'Moyenne ≥ 10/20 pour valider'),
          const SizedBox(height: AppSpacing.sm),
          _NavRow(
            icon: Icons.star_rounded,
            text: '${totalPoints.toStringAsFixed(totalPoints % 1 == 0 ? 0 : 1)} points au total',
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.nightBlueDeep,
                disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.18),
                disabledForegroundColor: AppColors.textDisabled,
                padding: const EdgeInsets.symmetric(vertical: 13),
                textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 17),
              label: const Text('Valider mes réponses'),
            ),
          ),
          if (!canSubmit) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Répondez à toutes les questions pour valider.',
              style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({required this.number, required this.answered, required this.onTap});

  final int number;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: answered ? 'Question $number — répondue' : 'Question $number',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: answered ? AppGradients.goldMetallic : null,
              color: answered ? null : AppColors.legalBlueDark.withValues(alpha: 0.5),
              border: Border.all(
                color: answered ? Colors.transparent : AppColors.gold.withValues(alpha: 0.4),
                width: 0.9,
              ),
            ),
            child: Text(
              '$number',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: answered ? AppColors.nightBlueDeep : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: AppColors.goldLight),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _DesktopQuestionCard extends StatelessWidget {
  const _DesktopQuestionCard({
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question $index',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppLetterSpacing.label,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _MiniTag(_typeLabel(question.type)),
                    _MiniTag(
                      '${question.points.toStringAsFixed(question.points % 1 == 0 ? 0 : 1)} pts',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question.statement,
            style: (textTheme.titleMedium ?? const TextStyle()).copyWith(
              fontFamily: 'Libre Caslon Display',
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (question.type == QuestionType.qcm)
            for (var i = 0; i < question.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _DesktopOption(
                  letter: String.fromCharCode(65 + i),
                  label: question.options[i],
                  selected: controller.answerFor(question.id) == i.toString(),
                  onTap: () => controller.answerQcm(question.id, i),
                ),
              )
          else
            GlowFocusField(
              child: TextField(
                controller: textController,
                maxLines: 5,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, height: 1.5),
                decoration: const InputDecoration(
                  hintText: 'Rédigez votre réponse — structurez, citez, illustrez…',
                  alignLabelWithHint: true,
                  filled: false,
                ),
                onChanged: (value) => controller.answerCasPratique(question.id, value),
              ),
            ),
        ],
      ),
    );
  }
}

class _DesktopOption extends StatefulWidget {
  const _DesktopOption({
    required this.letter,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_DesktopOption> createState() => _DesktopOptionState();
}

class _DesktopOptionState extends State<_DesktopOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            color: selected
                ? AppColors.gold.withValues(alpha: 0.13)
                : AppColors.legalBlueDark.withValues(alpha: _hovered ? 0.6 : 0.45),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.6)
                  : AppColors.gold.withValues(alpha: _hovered ? 0.3 : 0.14),
              width: selected ? 1 : 0.7,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? AppGradients.goldMetallic : null,
                  color: selected ? null : Colors.transparent,
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.textSecondary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  widget.letter,
                  style: textTheme.labelSmall?.copyWith(
                    color: selected ? AppColors.nightBlueDeep : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded, size: 16, color: AppColors.goldLight),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
//  Résultat + copie corrigée
// ---------------------------------------------------------------------------

class _DesktopResult extends StatelessWidget {
  const _DesktopResult({required this.controller, required this.module});

  final EvaluationController controller;
  final CourseModule? module;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final result = controller.result!;
    final evaluation = controller.evaluation!;
    final passed = result.passed;
    final hPad = MediaQuery.sizeOf(context).width < 600 ? AppSpacing.lg : AppSpacing.xl;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xxl, hPad, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              _ScoreRing(score: result.score, max: evaluation.maxScore, passed: passed),
              const SizedBox(height: AppSpacing.lg),
              Text(
                passed ? 'Module validé' : 'Pas encore validé',
                style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  passed
                      ? (result.unlockedNextModuleId != null
                          ? 'Bravo. Le module suivant vient d\'être débloqué.'
                          : 'Bravo. Vous avez validé le dernier module de ce niveau.')
                      : 'La moyenne requise est de 10/20. Revoyez la copie ci-dessous, puis reprenez avec un nouveau jeu de questions.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
              if (result.levelCompleted && result.unlockedNextLevel != null) ...[
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0x24C9A227), Color(0x0FC9A227)]),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.45), width: 0.9),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: AppColors.goldLight, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        child: Text(
                          'Niveau entièrement validé — ${result.unlockedNextLevel!.fullLabel} est débloqué !',
                          style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  if (!passed)
                    FilledButton.icon(
                      onPressed: controller.retryWithNewQuestions,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.nightBlueDeep,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                        textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Nouvelles questions'),
                    ),
                  (passed)
                      ? FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.nightBlueDeep,
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                            textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          icon: const Icon(Icons.arrow_back_rounded, size: 16),
                          label: const Text('Retour au module'),
                        )
                      : OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                          ),
                          child: const Text('Retour au module'),
                        ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Align(
                alignment: Alignment.centerLeft,
                child: const _Eyebrow('Votre copie, corrigée'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < evaluation.questions.length; i++)
                Padding(
                  padding: EdgeInsets.only(
                    bottom: i == evaluation.questions.length - 1 ? 0 : AppSpacing.md,
                  ),
                  child: _ReviewCard(index: i + 1, question: evaluation.questions[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.max, required this.passed});

  final double score;
  final double max;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final target = (max <= 0 ? 0.0 : score / max).clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target),
      duration: const Duration(milliseconds: 900),
      curve: Curves.fastOutSlowIn,
      builder: (context, value, _) {
        return SizedBox(
          width: 176,
          height: 176,
          child: CustomPaint(
            painter: _ScoreRingPainter(value: value, passed: passed),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: textTheme.displaySmall?.copyWith(
                        fontFamily: 'Libre Caslon Display',
                        color: passed ? AppColors.goldLight : AppColors.textPrimary,
                      ),
                      children: [
                        TextSpan(text: score.toStringAsFixed(1)),
                        TextSpan(
                          text: ' /${max.toStringAsFixed(0)}',
                          style: textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    passed ? 'Réussi' : 'À reprendre',
                    style: textTheme.labelSmall?.copyWith(
                      color: passed ? AppColors.success : AppColors.warning,
                      letterSpacing: AppLetterSpacing.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter({required this.value, required this.passed});

  final double value;
  final bool passed;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..color = AppColors.gold.withValues(alpha: 0.13),
    );

    // Repère du seuil de réussite (10/20 = 0.5).
    final thresholdAngle = start + 2 * math.pi * 0.5;
    final tickOuter = center + Offset(math.cos(thresholdAngle), math.sin(thresholdAngle)) * (radius + 7);
    final tickInner = center + Offset(math.cos(thresholdAngle), math.sin(thresholdAngle)) * (radius - 7);
    canvas.drawLine(
      tickInner,
      tickOuter,
      Paint()
        ..strokeWidth = 2
        ..color = AppColors.textSecondary.withValues(alpha: 0.6),
    );

    if (value <= 0) return;

    canvas.drawArc(
      rect,
      start,
      2 * math.pi * value,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..shader = (passed
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
                  )
                : const LinearGradient(
                    colors: [AppColors.warning, Color(0xFFB9863A)],
                  ))
            .createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.value != value || old.passed != passed;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.question});

  final int index;
  final EvaluationQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final grade = _gradeQuestion(question);
    final verdict = grade.verdict;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      borderColor: verdict.color.withValues(alpha: 0.35),
      borderWidth: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Question $index',
                style: textTheme.labelMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                  letterSpacing: AppLetterSpacing.label,
                ),
              ),
              const Spacer(),
              Icon(verdict.icon, size: 15, color: verdict.color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  '${verdict.label} · ${grade.awarded.toStringAsFixed(grade.awarded % 1 == 0 ? 0 : 1)}/${question.points.toStringAsFixed(question.points % 1 == 0 ? 0 : 1)}',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: verdict.color, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.statement,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          if (question.type == QuestionType.qcm)
            _QcmReview(question: question)
          else
            _CasReview(question: question),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.legalBlueDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border(
                  left: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'POURQUOI',
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.goldLight,
                      letterSpacing: AppLetterSpacing.label,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    question.explanation,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QcmReview extends StatelessWidget {
  const _QcmReview({required this.question});

  final EvaluationQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final chosen = int.tryParse(question.studentAnswer ?? '');

    return Column(
      children: [
        for (var i = 0; i < question.options.length; i++)
          () {
            final isCorrect = i == question.correctOptionIndex;
            final isChosen = i == chosen;
            final Color tint;
            final IconData? icon;
            if (isCorrect) {
              tint = AppColors.success;
              icon = Icons.check_rounded;
            } else if (isChosen) {
              tint = AppColors.error;
              icon = Icons.close_rounded;
            } else {
              tint = AppColors.textDisabled;
              icon = null;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  color: (isCorrect || isChosen)
                      ? tint.withValues(alpha: 0.10)
                      : Colors.transparent,
                  border: Border.all(
                    color: (isCorrect || isChosen)
                        ? tint.withValues(alpha: 0.4)
                        : AppColors.glassBorder,
                    width: 0.7,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      String.fromCharCode(65 + i),
                      style: textTheme.labelSmall?.copyWith(
                        color: tint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        question.options[i],
                        style: textTheme.bodySmall?.copyWith(
                          color: (isCorrect || isChosen)
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (isChosen && !isCorrect)
                      Text(
                        'votre choix',
                        style: textTheme.labelSmall?.copyWith(color: AppColors.error),
                      ),
                    if (icon != null) ...[
                      const SizedBox(width: 6),
                      Icon(icon, size: 14, color: tint),
                    ],
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }
}

class _CasReview extends StatelessWidget {
  const _CasReview({required this.question});

  final EvaluationQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final answer = (question.studentAnswer ?? '').trim();
    final answerLower = answer.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VOTRE RÉPONSE',
          style: textTheme.labelSmall?.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: AppLetterSpacing.label,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          answer.isEmpty ? '— (aucune réponse)' : answer,
          style: textTheme.bodySmall?.copyWith(
            color: answer.isEmpty ? AppColors.textDisabled : AppColors.textPrimary,
            height: 1.5,
            fontStyle: answer.isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
        if (question.expectedAnswerElements.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'ÉLÉMENTS ATTENDUS',
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: AppLetterSpacing.label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          for (final element in question.expectedAnswerElements)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      answerLower.contains(element.toLowerCase())
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 13,
                      color: answerLower.contains(element.toLowerCase())
                          ? AppColors.success
                          : AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      element,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
//  Éléments partagés du registre desktop
// ---------------------------------------------------------------------------

class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.legalBlueDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.glassBorder, width: 0.7),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 1, color: AppColors.gold.withValues(alpha: 0.6)),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.goldLight,
                  letterSpacing: AppLetterSpacing.caps,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

/// Fines poussières d'or en suspension — la respiration « vivante » du
/// registre desktop.
class _EvalAmbience extends StatefulWidget {
  const _EvalAmbience();

  @override
  State<_EvalAmbience> createState() => _EvalAmbienceState();
}

class _EvalAmbienceState extends State<_EvalAmbience> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 38))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(painter: _EvalAmbiencePainter(_controller.value)),
    );
  }
}

class _EvalAmbiencePainter extends CustomPainter {
  const _EvalAmbiencePainter(this.t);

  final double t;
  static const int _count = 13;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final seed = i * 55.0;
      final baseX = seed % size.width;
      final drift = math.sin((t * 2 * math.pi) + seed) * 20;
      final x = (baseX + drift) % size.width;
      final y = (size.height * ((i / _count) + t) % 1.0);
      final radius = 0.7 + (i % 3) * 0.6;
      final opacity = 0.04 + 0.07 * (0.5 + 0.5 * math.sin((t * 2 * math.pi) + seed * 1.7));
      paint.color = AppColors.goldLight.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EvalAmbiencePainter oldDelegate) => oldDelegate.t != t;
}
