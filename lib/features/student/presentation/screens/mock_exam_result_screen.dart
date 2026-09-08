import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/widgets/glass_container.dart';
import '../../../../models/student/evaluation_model.dart';
import '../../../../models/student/mock_exam_model.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/mock_exam_controller.dart';

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

_Verdict _verdictOf(EvaluationQuestion q) {
  final awarded = q.awardedPoints ?? 0;
  if (q.points <= 0) return _Verdict.wrong;
  final fraction = awarded / q.points;
  if (fraction >= 0.999) return _Verdict.correct;
  if (fraction <= 0.001) return _Verdict.wrong;
  return _Verdict.partial;
}

String _disqualificationLabel(MockExamDisqualificationReason reason) => switch (reason) {
      MockExamDisqualificationReason.suspiciousNoise => 'Bruit ambiant suspect détecté',
      MockExamDisqualificationReason.suspiciousMotion => 'Mouvement suspect détecté par la caméra',
    };

/// Résultat d'une tentative d'examen blanc : anneau de score animé, verdict,
/// note de verrou en cas d'échec (par la note ou par disqualification du
/// proctoring), et copie corrigée question par question.
class MockExamResultBody extends StatelessWidget {
  const MockExamResultBody({super.key, required this.controller});

  final MockExamController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final exam = controller.exam!;
    final passed = exam.isPassed;
    final disqualification = exam.disqualificationReason;
    final hPad = MediaQuery.sizeOf(context).width < 600 ? AppSpacing.lg : AppSpacing.xl;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xxl, hPad, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              _MockScoreRing(score: exam.score ?? 0, max: exam.maxScore, passed: passed),
              const SizedBox(height: AppSpacing.lg),
              Text(
                disqualification != null
                    ? 'Épreuve interrompue'
                    : passed
                        ? 'Examen blanc réussi'
                        : 'Examen blanc non validé',
                style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              if (disqualification != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 0.7),
                  ),
                  child: Text(
                    _disqualificationLabel(disqualification),
                    style: textTheme.labelSmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  disqualification != null
                      ? 'Le proctoring a détecté une anomalie pendant l\'épreuve — la tentative est '
                          'automatiquement invalidée et l\'épreuve verrouillée pendant 7 jours ; '
                          'reconsultez le cours de ce niveau pour pouvoir retenter dès le délai écoulé.'
                      : passed
                          ? 'Bravo, la moyenne requise de 10/20 est atteinte.'
                          : 'La moyenne requise est de 10/20. L\'épreuve est verrouillée pendant 7 jours ; '
                              'reconsultez le cours de ce niveau pour pouvoir retenter dès le délai écoulé.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ),
              if (exam.isReducedFallback) ...[
                const SizedBox(height: AppSpacing.md),
                _ReducedFallbackNotice(),
              ],
              const SizedBox(height: AppSpacing.xl),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Retour au niveau'),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Align(
                alignment: Alignment.centerLeft,
                child: _Eyebrow('Votre copie, corrigée'),
              ),
              const SizedBox(height: AppSpacing.md),
              for (var i = 0; i < exam.questions.length; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == exam.questions.length - 1 ? 0 : AppSpacing.md),
                  child: _ReviewCard(index: i + 1, question: exam.questions[i]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReducedFallbackNotice extends StatelessWidget {
  const _ReducedFallbackNotice();

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.warning.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Banque de secours limitée : connexion IA indisponible, l'examen a porté sur moins de "
              'questions que prévu.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockScoreRing extends StatelessWidget {
  const _MockScoreRing({required this.score, required this.max, required this.passed});

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
            painter: _MockScoreRingPainter(value: value, passed: passed),
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
                    passed ? 'Réussi' : 'Verrouillé 7 jours',
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

class _MockScoreRingPainter extends CustomPainter {
  const _MockScoreRingPainter({required this.value, required this.passed});

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
                : const LinearGradient(colors: [AppColors.warning, Color(0xFFB9863A)]))
            .createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _MockScoreRingPainter old) => old.value != value || old.passed != passed;
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.index, required this.question});

  final int index;
  final EvaluationQuestion question;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final verdict = _verdictOf(question);
    final awarded = question.awardedPoints ?? 0;

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
              Text(
                '${verdict.label} · ${awarded.toStringAsFixed(1)}/${question.points.toStringAsFixed(1)}',
                style: textTheme.labelSmall?.copyWith(color: verdict.color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            question.statement,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
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
            (question.studentAnswer ?? '').trim().isEmpty ? '— (aucune réponse)' : question.studentAnswer!.trim(),
            style: textTheme.bodySmall?.copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
          if (question.explanation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.legalBlueDark.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(AppRadius.small),
                border: Border(left: BorderSide(color: AppColors.gold.withValues(alpha: 0.5), width: 2)),
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
