import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/ai/groq_providers.dart';
import '../../../../core/exam/exam_voice_unlock.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/jurisia_mark.dart';
import '../../../../core/widgets/luxury_scaffold_background.dart';
import '../../../../models/student/student_level.dart';
import '../../../../theme/app_theme.dart';
import '../../data/datasources/ai_answer_grader.dart';
import '../../data/datasources/mock_exam_question_source.dart';
import '../controllers/mock_exam_controller.dart';
import '../controllers/student_controller.dart';
import '../student_providers.dart';
import '../widgets/mock_exam_ambience.dart';
import 'mock_exam_result_screen.dart';
import 'mock_exam_voice_screen.dart';

/// Point d'entrée de l'examen blanc de fin de niveau : verrou, briefing,
/// puis l'épreuve elle-même (conversation vocale unique — voir
/// [MockExamVoiceBody]) et son résultat — tout piloté par un seul
/// [MockExamController], comme [EvaluationScreen] pour le quiz de module.
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
        onPassed: () => studentController.recordMockExamPassed(level),
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

    // L'épreuve elle-même occupe tout l'écran en noir immersif, façon
    // Voice Mode — sans le dégradé/en-tête/ambiance dorée des autres états,
    // volontairement en rupture avec le reste de l'app pour cet écran.
    if (controller.status == MockExamStatus.inProgress) {
      return _InProgressView(controller: controller);
    }

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
        return _BriefingView(controller: controller);
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

/// Épreuve plein écran, en rupture assumée avec l'habillage doré habituel
/// de l'écran — conserve un `Scaffold` propre pour que la notification
/// d'interruption (SnackBar) reste affichable.
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

    return Scaffold(
      backgroundColor: Colors.black,
      body: MockExamVoiceBody(controller: controller),
    );
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
                onPressed: () {
                  primeWebSpeechSynthesis();
                  primeWebMicrophonePermission();
                  controller.retry();
                },
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

/// Briefing avant le démarrage : plus de choix de format — un seul bouton,
/// les règles de l'épreuve (silence, caméra/micro actifs, repli clavier)
/// rappelées clairement avant d'entrer dans la conversation vocale.
class _BriefingView extends StatelessWidget {
  const _BriefingView({required this.controller});

  final MockExamController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppGradients.goldMetallic),
                child: const Icon(Icons.graphic_eq_rounded, color: AppColors.nightBlueDeep, size: 38),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Examen blanc — Voice Mode',
                textAlign: TextAlign.center,
                style: textTheme.displaySmall?.copyWith(fontFamily: 'Libre Caslon Display'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Une conversation vocale continue avec l\'IA : ${MockExamQuestionSource.questionCount} questions, '
                'notée sur 20 (seuil de réussite : 10/20). En cas d\'échec, l\'épreuve est verrouillée 7 jours '
                'et le cours doit être reconsulté.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.xl),
              GlassContainer(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RuleRow(
                      icon: Icons.volume_up_rounded,
                      text: 'Installez-vous dans un endroit calme — un bruit ambiant suspect entraîne '
                          "l'échec immédiat de la tentative.",
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _RuleRow(
                      icon: Icons.videocam_rounded,
                      text: "Caméra et micro actifs pendant toute l'épreuve — une agitation ou une sortie "
                          "de cadre entraîne aussi l'échec immédiat.",
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _RuleRow(
                      icon: Icons.phonelink_ring_rounded,
                      text: "Quitter l'application ou le plein écran régénère un tout nouveau jeu de "
                          'questions.',
                    ),
                    SizedBox(height: AppSpacing.sm),
                    _RuleRow(
                      icon: Icons.keyboard_rounded,
                      text: 'Un repli clavier reste toujours disponible si la reconnaissance vocale échoue.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: () {
                  // Synchrone, avant tout aller-retour réseau : sur web,
                  // inscrit l'activation utilisateur nécessaire à la
                  // synthèse vocale (voir exam_voice_unlock_web.dart).
                  primeWebSpeechSynthesis();
                  primeWebMicrophonePermission();
                  controller.start();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.nightBlueDeep,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 16),
                  textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text("Commencer l'examen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.goldLight),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
        ),
      ],
    );
  }
}
