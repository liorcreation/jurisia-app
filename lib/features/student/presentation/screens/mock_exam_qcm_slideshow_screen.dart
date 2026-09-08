import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../models/student/evaluation_model.dart';
import '../../../../theme/app_theme.dart';
import '../controllers/mock_exam_controller.dart';

/// Mode A — QCM chronométré : diapositives plein écran défilant en avant
/// uniquement (pas de retour arrière), 5 secondes maximum par question, avec
/// soumission et avancement automatiques à expiration du délai.
class MockExamQcmSlideshowBody extends StatefulWidget {
  const MockExamQcmSlideshowBody({super.key, required this.controller});

  final MockExamController controller;

  @override
  State<MockExamQcmSlideshowBody> createState() => _MockExamQcmSlideshowBodyState();
}

class _MockExamQcmSlideshowBodyState extends State<MockExamQcmSlideshowBody>
    with SingleTickerProviderStateMixin {
  static const _perQuestion = Duration(seconds: 5);

  late final PageController _pageController = PageController();
  late final AnimationController _timerController =
      AnimationController(vsync: this, duration: _perQuestion)
        ..addStatusListener(_onTimerStatus)
        ..forward();

  int _index = 0;
  bool _advancing = false;

  void _onTimerStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _advance();
  }

  void _selectOption(String questionId, int optionIndex) {
    if (_advancing) return;
    widget.controller.answerQcm(questionId, optionIndex);
    _advance();
  }

  Future<void> _advance() async {
    if (_advancing) return;
    _advancing = true;
    _timerController.stop();

    final questions = widget.controller.exam!.questions;
    if (_index >= questions.length - 1) {
      await widget.controller.submit();
      return;
    }

    if (!mounted) return;
    setState(() => _index++);
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
    );
    if (!mounted) return;
    _timerController
      ..reset()
      ..forward();
    _advancing = false;
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.controller.exam!.questions;

    return Column(
      children: [
        _TopBar(index: _index, total: questions.length, timerController: _timerController),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            itemBuilder: (context, i) => _QcmSlide(
              question: questions[i],
              selected: widget.controller.answerFor(questions[i].id),
              onSelect: (optionIndex) => _selectOption(questions[i].id, optionIndex),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.index, required this.total, required this.timerController});

  final int index;
  final int total;
  final AnimationController timerController;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : (index + 1) / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: Stack(
                children: [
                  Container(height: 5, color: AppColors.legalBlueDark),
                  FractionallySizedBox(
                    widthFactor: progress <= 0 ? 0.001 : progress,
                    child: Container(height: 5, decoration: const BoxDecoration(gradient: AppGradients.goldMetallic)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${index + 1} / $total',
            style: textTheme.labelMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          AnimatedBuilder(
            animation: timerController,
            builder: (context, _) => _CountdownRing(remaining: 1 - timerController.value),
          ),
        ],
      ),
    );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({required this.remaining});

  /// 1 en début de question, 0 à expiration.
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final seconds = (remaining * 5).ceil().clamp(0, 5);

    return SizedBox(
      width: 36,
      height: 36,
      child: CustomPaint(
        painter: _RingPainter(remaining),
        child: Center(
          child: Text(
            '$seconds',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.remaining);

  final double remaining;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = AppColors.gold.withValues(alpha: 0.15),
    );

    if (remaining <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * remaining,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = remaining < 0.34 ? AppColors.error : AppColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => oldDelegate.remaining != remaining;
}

class _QcmSlide extends StatelessWidget {
  const _QcmSlide({required this.question, required this.selected, required this.onSelect});

  final EvaluationQuestion question;
  final String? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.lg : AppSpacing.xxl, vertical: AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                question.statement,
                textAlign: TextAlign.center,
                style: (compact ? textTheme.headlineSmall : textTheme.displaySmall)?.copyWith(
                  fontFamily: 'Libre Caslon Display',
                  height: 1.3,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              for (var i = 0; i < question.options.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _SlideOption(
                    letter: String.fromCharCode(65 + i),
                    label: question.options[i],
                    selected: selected == i.toString(),
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SlideOption extends StatefulWidget {
  const _SlideOption({required this.letter, required this.label, required this.selected, required this.onTap});

  final String letter;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SlideOption> createState() => _SlideOptionState();
}

class _SlideOptionState extends State<_SlideOption> {
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            color: selected
                ? AppColors.gold.withValues(alpha: 0.14)
                : AppColors.legalBlueDark.withValues(alpha: _hovered ? 0.65 : 0.5),
            border: Border.all(
              color: selected
                  ? AppColors.gold.withValues(alpha: 0.65)
                  : AppColors.gold.withValues(alpha: _hovered ? 0.32 : 0.16),
              width: selected ? 1.1 : 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: selected ? AppGradients.goldMetallic : null,
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  widget.letter,
                  style: textTheme.labelMedium?.copyWith(
                    color: selected ? AppColors.nightBlueDeep : AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  widget.label,
                  style: textTheme.bodyLarge?.copyWith(
                    color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
              if (selected) const Icon(Icons.check_rounded, size: 18, color: AppColors.goldLight),
            ],
          ),
        ),
      ),
    );
  }
}
