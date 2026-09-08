import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/groq_providers.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/jurisia_mark.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/student/mock_exam_model.dart';
import '../../../../models/student/student_level.dart';
import '../../../../theme/app_theme.dart';
import '../../data/datasources/ai_answer_grader.dart';
import '../controllers/mock_exam_controller.dart';
import '../controllers/student_controller.dart';
import '../student_providers.dart';
import '../widgets/mock_exam_ambience.dart';
import 'mock_exam_oral_screen.dart';
import 'mock_exam_qcm_slideshow_screen.dart';
import 'mock_exam_result_screen.dart';
import 'mock_exam_written_screen.dart';

/// Point d'entrée de l'examen blanc de fin de niveau : verrou, choix du
/// format (QCM chronométré / devoir écrit / examen oral), puis l'épreuve
/// elle-même et son résultat — tout piloté par un seul [MockExamController],
/// comme [EvaluationScreen] pour le quiz de module.
class MockExamScreen extends StatelessWidget {
  const MockExamScreen({super.key, required this.level});

  final AcademicLevel level;

  @override
  Widget build(BuildContext context) {
    final studentController = context.read<StudentController>();
    final levelModules = studentController.modulesForLevel(level);

    return ChangeNotifierProvider<MockExamController>(
      create: (_) => MockExamController(
        level: level,
        levelModules: levelModules,
        repository: buildMockExamRepository(),
        answerGrader: AiAnswerGrader(dataSource: buildGroqDataSource()),
      ),
      child: const _MockExamFlow(),
    );
  }
}

class _MockExamFlow extends StatelessWidget {
  const _MockExamFlow();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MockExamController>();

    return LuxuryScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(child: IgnorePointer(child: MockExamAmbience())),
              Column(
                children: [
                  _Header(controller: controller),
                  Expanded(child: _Body(controller: controller)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final MockExamController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final compact = MediaQuery.sizeOf(context).width < 600;

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.smokedGlass,
        border: Border(bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18), width: 0.6)),
      ),
      padding: EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, compact ? AppSpacing.sm : AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Quitter',
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  compact ? 'Examen blanc' : 'Examen blanc de fin de niveau',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: compact
                      ? textTheme.titleMedium?.copyWith(fontFamily: 'Libre Caslon Display')
                      : textTheme.headlineSmall,
                ),
                Text(
                  controller.level.fullLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final MockExamController controller;

  @override
  Widget build(BuildContext context) {
    switch (controller.status) {
      case MockExamStatus.loadingLock:
        return const _CenteredLoading(label: 'Chargement…');
      case MockExamStatus.locked:
        return _LockedView(controller: controller);
      case MockExamStatus.readyToStart:
        return _ModeSelectView(controller: controller);
      case MockExamStatus.generating:
        return const _CenteredLoading(label: "L'IA compose votre examen…");
      case MockExamStatus.grading:
        return const _CenteredLoading(label: 'Correction en cours…');
      case MockExamStatus.error:
        return _ErrorView(controller: controller);
      case MockExamStatus.inProgress:
        return _InProgressView(controller: controller);
      case MockExamStatus.submitted:
        return MockExamResultBody(controller: controller);
    }
  }
}

class _InProgressView extends StatelessWidget {
  const _InProgressView({required this.controller});

  final MockExamController controller;

  @override
  Widget build(BuildContext context) {
    final notice = controller.interruptionNotice;
    if (notice != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
        controller.dismissInterruptionNotice();
      });
    }

    switch (controller.selectedMode!) {
      case MockExamMode.qcmTimed:
        return MockExamQcmSlideshowBody(controller: controller);
      case MockExamMode.written:
        return MockExamWrittenBody(controller: controller);
      case MockExamMode.oral:
        return MockExamOralBody(controller: controller);
    }
  }
}

class _CenteredLoading extends StatelessWidget {
  const _CenteredLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _PulsingMark(),
          const SizedBox(height: AppSpacing.xl),
          Text(label, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display')),
        ],
      ),
    );
  }
}

class _PulsingMark extends StatefulWidget {
  const _PulsingMark();

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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.controller});

  final MockExamController controller;

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
                controller.errorMessage ?? 'Une erreur est survenue.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: controller.retry,
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

class _LockedView extends StatelessWidget {
  const _LockedView({required this.controller});

  final MockExamController controller;

  String _remainingLabel(Duration remaining) {
    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    if (days > 0) return '${days}j ${hours}h';
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}min';
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lock = controller.lockState!;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.xl),
          borderColor: AppColors.warning.withValues(alpha: 0.4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_clock_rounded, color: AppColors.warning, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Examen blanc verrouillé',
                style: textTheme.headlineSmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (lock.isLocked) ...[
                Text(
                  'Nouvelle tentative possible dans ${_remainingLabel(lock.remaining!)}.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (lock.requiresCourseReview)
                Text(
                  'Reconsultez le cours de ce niveau dans l\'onglet Cours pour débloquer la prochaine tentative.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              const SizedBox(height: AppSpacing.lg),
              OutlinedButton.icon(
                onPressed: controller.refreshLockState,
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12)),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Vérifier à nouveau'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeSelectView extends StatelessWidget {
  const _ModeSelectView({required this.controller});

  final MockExamController controller;

  static const _modes = <(MockExamMode, IconData, String, String, String)>[
    (
      MockExamMode.qcmTimed,
      Icons.timer_rounded,
      'QCM chronométré',
      '40 questions · 5 s chacune',
      'Diapositives défilantes, une question à la fois — le rythme le plus intense.',
    ),
    (
      MockExamMode.written,
      Icons.edit_note_rounded,
      'Devoir écrit',
      '16 à 20 questions',
      'Rédigez vos réponses à votre rythme, sans minuteur par question.',
    ),
    (
      MockExamMode.oral,
      Icons.graphic_eq_rounded,
      'Examen oral',
      'Voice Mode',
      "L'IA énonce les questions à voix haute, vous répondez oralement.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choisissez votre format',
                style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Un examen blanc à l\'échelle du niveau, noté sur 20 (seuil de réussite : 10/20). '
                'En cas d\'échec, l\'épreuve est verrouillée 7 jours et le cours doit être reconsulté.',
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 820;
                  final cardWidth = wide ? (constraints.maxWidth - AppSpacing.md * 2) / 3 : constraints.maxWidth;
                  return Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      for (final mode in _modes)
                        SizedBox(
                          width: cardWidth,
                          child: _ModeCard(
                            icon: mode.$2,
                            title: mode.$3,
                            meta: mode.$4,
                            description: mode.$5,
                            onTap: () => controller.start(mode.$1),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatefulWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String meta;
  final String description;
  final VoidCallback onTap;

  @override
  State<_ModeCard> createState() => _ModeCardState();
}

class _ModeCardState extends State<_ModeCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GlassContainer(
        onTap: widget.onTap,
        padding: const EdgeInsets.all(AppSpacing.lg),
        borderColor: AppColors.gold.withValues(alpha: _hovered ? 0.5 : 0.22),
        borderWidth: _hovered ? 1 : 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppGradients.goldMetallic,
              ),
              child: Icon(widget.icon, color: AppColors.nightBlueDeep, size: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(widget.title, style: textTheme.titleLarge?.copyWith(fontFamily: 'Libre Caslon Display')),
            const SizedBox(height: 4),
            Text(widget.meta, style: textTheme.labelMedium?.copyWith(color: AppColors.goldLight, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(widget.description, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, height: 1.45)),
            const SizedBox(height: AppSpacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: widget.onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.nightBlueDeep,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Démarrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
