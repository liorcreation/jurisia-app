import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/evaluation_controller.dart';

/// Épreuve QCM à diapositives : une question visible cinq secondes maximum,
/// puis passage automatique à la suivante. Le chrono est local à l'interface
/// pour rester fluide même lorsque la caméra réalise une capture.
class TimedQcmEvaluationView extends StatefulWidget {
  const TimedQcmEvaluationView({super.key, required this.controller});

  final EvaluationController controller;

  @override
  State<TimedQcmEvaluationView> createState() => _TimedQcmEvaluationViewState();
}

class _TimedQcmEvaluationViewState extends State<TimedQcmEvaluationView> {
  static const _questionDuration = Duration(seconds: 5);
  Timer? _timer;
  Stopwatch _stopwatch = Stopwatch();
  int _index = 0;
  double _remaining = 1;
  bool _advancing = false;

  @override
  void initState() {
    super.initState();
    _startQuestionClock();
  }

  void _startQuestionClock() {
    _timer?.cancel();
    _stopwatch = Stopwatch()..start();
    _remaining = 1;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _advancing) return;
      final progress = 1 - (_stopwatch.elapsedMilliseconds / _questionDuration.inMilliseconds);
      if (progress <= 0) {
        _advance();
      } else {
        setState(() => _remaining = progress);
      }
    });
  }

  void _answer(int optionIndex) {
    if (_advancing) return;
    widget.controller.answerQcm(widget.controller.evaluation!.questions[_index].id, optionIndex);
    _advance();
  }

  void _advance() {
    if (_advancing) return;
    _advancing = true;
    _stopwatch.stop();
    final total = widget.controller.evaluation?.questions.length ?? 0;
    if (_index >= total - 1) {
      _timer?.cancel();
      widget.controller.submitTimedQcm();
      return;
    }
    setState(() {
      _index++;
      _advancing = false;
    });
    _startQuestionClock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = widget.controller.evaluation!;
    final question = evaluation.questions[_index];
    final answered = widget.controller.answerFor(question.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _ModePill(label: 'QCM DIAPOS', color: AppColors.cobaltLight),
                  const Spacer(),
                  Text(
                    '${_index + 1} / ${evaluation.questions.length}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  minHeight: 7,
                  value: _remaining,
                  backgroundColor: AppColors.textSecondary.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _remaining < 0.25 ? AppColors.error : AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.xl),
                borderColor: AppColors.gold.withValues(alpha: 0.35),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Répondez avant la fin du compte à rebours',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppColors.goldLight,
                            letterSpacing: AppLetterSpacing.label,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(question.statement, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: AppSpacing.xl),
                    for (var i = 0; i < question.options.length; i++) ...[
                      _AnswerTile(
                        index: i,
                        label: question.options[i],
                        selected: answered == i.toString(),
                        onTap: () => _answer(i),
                      ),
                      if (i < question.options.length - 1) const SizedBox(height: AppSpacing.sm),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Une réponse non sélectionnée à l’expiration vaut zéro et la diapositive suivante s’affiche automatiquement.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.index, required this.label, required this.selected, required this.onTap});
  final int index;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.gold : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.gold.withValues(alpha: 0.14) : AppColors.textPrimary.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: selected ? AppColors.gold : AppColors.glassBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Text(String.fromCharCode(65 + index), style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
