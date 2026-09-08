import 'package:flutter/material.dart';

import '../../../../core/widgets/entrance_fade.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/glow_focus_field.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/mock_exam_controller.dart';

/// Mode B — Devoir écrit : 16 à 20 questions rédigées, sans minuteur par
/// question (seule la règle anti-changement d'application s'applique
/// pendant toute la session, portée par [MockExamController]).
class MockExamWrittenBody extends StatefulWidget {
  const MockExamWrittenBody({super.key, required this.controller});

  final MockExamController controller;

  @override
  State<MockExamWrittenBody> createState() => _MockExamWrittenBodyState();
}

class _MockExamWrittenBodyState extends State<MockExamWrittenBody> {
  final ScrollController _scroll = ScrollController();
  final Map<String, TextEditingController> _textControllers = {};
  late final List<GlobalKey> _keys;

  TextEditingController _controllerFor(String id) =>
      _textControllers.putIfAbsent(id, () => TextEditingController(text: widget.controller.answerFor(id)));

  @override
  void initState() {
    super.initState();
    _keys = List.generate(widget.controller.exam!.questions.length, (_) => GlobalKey());
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
    final exam = controller.exam!;
    final questions = exam.questions;
    final answered = [
      for (final q in questions) (controller.answerFor(q.id) ?? '').trim().isNotEmpty,
    ];
    final answeredCount = answered.where((e) => e).length;

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
              const _Eyebrow('Devoir écrit'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Composez votre copie',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Répondez aux ${questions.length} questions. La moyenne requise pour valider l\'examen '
                'blanc est de 10/20.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(width: 54, height: 2, color: AppColors.gold.withValues(alpha: 0.7)),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < questions.length; i++)
                KeyedSubtree(
                  key: _keys[i],
                  child: Padding(
                    padding: EdgeInsets.only(bottom: i == questions.length - 1 ? 0 : AppSpacing.lg),
                    child: EntranceFadeSlide(
                      index: i,
                      child: _WrittenQuestionCard(
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
              SizedBox(
                width: 300,
                child: _WrittenNavigator(
                  answered: answered,
                  answeredCount: answeredCount,
                  total: questions.length,
                  canSubmit: controller.allQuestionsAnswered,
                  onSubmit: controller.submit,
                  onJump: _scrollTo,
                ),
              ),
              Expanded(child: scroller),
            ],
          );
        }
        return Column(
          children: [
            Expanded(child: scroller),
            _MobileWrittenBar(
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

class _WrittenQuestionCard extends StatelessWidget {
  const _WrittenQuestionCard({
    required this.index,
    required this.question,
    required this.controller,
    required this.textController,
  });

  final int index;
  final EvaluationQuestion question;
  final MockExamController controller;
  final TextEditingController? textController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $index',
            style: textTheme.labelMedium?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
              letterSpacing: AppLetterSpacing.label,
            ),
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
                child: _WrittenOption(
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
                maxLines: 6,
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

class _WrittenOption extends StatelessWidget {
  const _WrittenOption({required this.letter, required this.label, required this.selected, required this.onTap});

  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            color: selected ? AppColors.gold.withValues(alpha: 0.13) : AppColors.legalBlueDark.withValues(alpha: 0.45),
            border: Border.all(
              color: selected ? AppColors.gold.withValues(alpha: 0.6) : AppColors.gold.withValues(alpha: 0.14),
              width: selected ? 1 : 0.7,
            ),
          ),
          child: Row(
            children: [
              Text(letter, style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary))),
              if (selected) const Icon(Icons.check_rounded, size: 16, color: AppColors.goldLight),
            ],
          ),
        ),
      ),
    );
  }
}

class _WrittenNavigator extends StatelessWidget {
  const _WrittenNavigator({
    required this.answered,
    required this.answeredCount,
    required this.total,
    required this.canSubmit,
    required this.onSubmit,
    required this.onJump,
  });

  final List<bool> answered;
  final int answeredCount;
  final int total;
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
              for (var i = 0; i < total; i++) _NavPill(number: i + 1, answered: answered[i], onTap: () => onJump(i)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('$answeredCount / $total répondu${answeredCount > 1 ? 'es' : 'e'}',
              style: textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display')),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(height: 6, color: AppColors.legalBlueDark),
                FractionallySizedBox(
                  widthFactor: fraction <= 0 ? 0.001 : fraction,
                  child: Container(height: 6, decoration: const BoxDecoration(gradient: AppGradients.goldMetallic)),
                ),
              ],
            ),
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
              label: const Text('Rendre ma copie'),
            ),
          ),
          if (!canSubmit) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Répondez à toutes les questions pour valider.',
                style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
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
    return Material(
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
    );
  }
}

class _MobileWrittenBar extends StatelessWidget {
  const _MobileWrittenBar({
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
        border: Border(top: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6)),
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
                Text('$answeredCount / $total répondue${answeredCount > 1 ? 's' : ''}',
                    style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary)),
                const Spacer(),
                if (!canSubmit)
                  Text('Répondez à tout pour valider', style: textTheme.labelSmall?.copyWith(color: AppColors.textDisabled)),
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
                    child: Container(height: 5, decoration: const BoxDecoration(gradient: AppGradients.goldMetallic)),
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
              label: const Text('Rendre ma copie'),
            ),
          ],
        ),
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
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.goldLight,
                letterSpacing: AppLetterSpacing.caps,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
